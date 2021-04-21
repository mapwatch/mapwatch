module Mapwatch.RawMapRun exposing
    ( NpcEncounters
    , RawMapRun
    , State
    , current
    , duration
    , tick
    , update
    , updateNPCText
    , updatedAt
    )

{-| Run data optimized for log processing, run-splitting, and other updates.

Not useful for display or detailed interpretation of the data;
needlessly detailed for historical data. Use MapRun for those.

-}

import Dict exposing (Dict)
import Duration exposing (Millis)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Debug
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.Visit as Visit exposing (Visit)
import Time exposing (Posix)


type alias RawMapRun =
    { address : Instance.Address
    , startedAt : Posix
    , portals : Int
    , npcSays : NpcEncounters
    , visits : List Visit
    , isAbandoned : Bool
    , positionStart : Int
    , positionEnd : Int
    }


type alias State =
    Maybe RawMapRun


type alias NpcEncounters =
    Dict NpcGroup (List ( LogLine.NPCSaysData, Instance ))


create : Instance.Address -> Posix -> NpcEncounters -> Int -> Int -> Maybe RawMapRun
create addr startedAt npcSays posStart posEnd =
    if Instance.isMap (Instance.Instance addr) then
        Just
            { address = addr
            , startedAt = startedAt
            , npcSays = npcSays
            , visits = []
            , portals = 1
            , isAbandoned = False
            , positionStart = posStart
            , positionEnd = posEnd
            }

    else
        Nothing


duration : RawMapRun -> Millis
duration r =
    Time.posixToMillis (updatedAt r) - Time.posixToMillis r.startedAt |> max 0


updatedAt : RawMapRun -> Posix
updatedAt r =
    case List.head r.visits of
        Just last ->
            last.leftAt

        Nothing ->
            r.startedAt


push : Visit -> RawMapRun -> Maybe RawMapRun
push visit run =
    if Visit.isOffline visit then
        if Visit.isTown visit then
            -- offline in town: run's over
            Nothing

        else
            -- offline, out of town: run's abandoned. We don't know how long it was!
            Just { run | isAbandoned = True }

    else
        Just { run | visits = visit :: run.visits, positionEnd = visit.positionEnd }


tick : Posix -> Instance.State -> State -> ( State, Maybe RawMapRun )
tick now instance_ state =
    -- go offline when time has passed since the last log entry.
    case state of
        Nothing ->
            ( Nothing, Nothing )

        Just run ->
            if Instance.isOffline now instance_ then
                -- they went offline during a run. Start a new run.
                if Instance.isTown instance_.val then
                    -- they went offline in town - end the run, discarding the time in town.
                    ( Nothing, Just run )
                        |> Mapwatch.Debug.log "Run.tick: Running<town> -> offline"

                else
                    -- they went offline in the map or a side area.
                    -- abandon the run: we can't know how much time they actually spent running before disappearing.
                    ( Nothing, Just { run | isAbandoned = True } )
                        |> Mapwatch.Debug.log "Run.tick: Running<not-town> -> offline"

            else
                -- no changes
                ( state, Nothing )


current : Posix -> Maybe Instance.State -> State -> Maybe RawMapRun
current now minstance_ state =
    case minstance_ of
        Nothing ->
            Nothing

        Just instance_ ->
            let
                visitResult v =
                    case update instance_ (Just v) state of
                        ( _, Just run ) ->
                            Just run

                        ( Just run, _ ) ->
                            Just run

                        _ ->
                            Nothing
            in
            case state of
                Nothing ->
                    Nothing

                Just raw ->
                    Visit.initSince instance_ now raw.positionStart raw.positionEnd
                        |> visitResult


update : Instance.State -> Maybe Visit -> State -> ( State, Maybe RawMapRun )
update instance_ mvisit state =
    -- we just joined `instance`, and just left `visit.instance`.
    --
    -- instance may be Nothing (the game just reopened) - the visit is
    -- treated as if the player were online while the game was closed,
    -- and restarted instantly into no-instance.
    -- No-instance always transitions to town (the player starts there).
    case mvisit of
        Nothing ->
            -- no visit, no changes.
            ( state, Nothing )

        Just visit ->
            let
                initRun : NpcEncounters -> Maybe RawMapRun
                initRun npcSays =
                    if Instance.isMap instance_.val && Visit.isTown visit then
                        -- when not running, entering a map from town starts a run.
                        Instance.unwrap Nothing
                            (\addr -> create addr instance_.joinedAt npcSays visit.positionStart visit.positionEnd)
                            instance_.val

                    else
                        Nothing
            in
            case state of
                Nothing ->
                    ( initRun Dict.empty, Nothing )

                Just running ->
                    case push visit running of
                        Nothing ->
                            -- they went offline in town - end the run, discarding the time in town.
                            ( initRun Dict.empty
                            , if duration running == 0 then
                                Nothing

                              else
                                Just running
                            )

                        Just run ->
                            if run.isAbandoned then
                                -- they went offline without returning to town first - we don't know how long the run was.
                                -- End the run (we'll have a special display for this case later).
                                ( initRun Dict.empty, Just run )

                            else if (not <| Instance.isTown instance_.val) && instance_.val /= Instance.Instance run.address && Visit.isTown visit then
                                -- entering a new non-town zone, from town, finishes this run and might start a new one. This condition is complex:
                                -- * Reentering the same map does not! Ex: death, or portal-to-town to dump some gear.
                                -- * Map -> Map does not! Ex: a Zana mission. TODO Zanas ought to split off into their own run, though.
                                -- * Even Non-Map -> Map does not! That's a Zana daily, or leaving an abyssal-depth/trial/other side-area.
                                -- * Town -> Non-Map does, though. Ex: map -> town -> uberlab.
                                ( initRun Dict.empty, Just run )

                            else if instance_.val == Instance.Instance run.address && Visit.isTown visit then
                                -- reentering the *same* map from town is a portal.
                                ( Just { run | portals = run.portals + 1 }, Nothing )

                            else
                                -- the common case - just add the visit to the run
                                ( Just run, Nothing )


updateNPCText : LogLine.Line -> Instance -> State -> State
updateNPCText line instance state =
    case line.info of
        LogLine.NPCSays says ->
            state |> Maybe.map (\run -> { run | npcSays = run.npcSays |> pushNpcEncounter says instance })

        _ ->
            state


pushNpcEncounter : LogLine.NPCSaysData -> Instance -> NpcEncounters -> NpcEncounters
pushNpcEncounter says instance =
    Dict.update (NpcId.toNpcGroup says.npcId) (Maybe.withDefault [] >> (::) ( says, instance ) >> Just)
