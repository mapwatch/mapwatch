module Mapwatch.Instance exposing
    ( Address
    , AddressId
    , Builder(..)
    , Instance(..)
    , State
    , addressId
    , afkOff
    , duration
    , init
    , initOrUpdate
    , isDurationOffline
    , isMap
    , isOffline
    , isTown
    , offlineThreshold
    , toAddress
    , unwrap
    , update
    , worldArea
    , zoneName
    )

import Duration exposing (Millis)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.LogLine as LogLine
import Maybe.Extra
import Time exposing (Posix)


{-| "Uniquely" identify a PoE zone instance.

(Zone, instance-server-address) isn't really a unique id - imagine running two
Volcano maps that just so happen to be assigned to the same instance server.
It's the best we've got though, and it works pretty well in practice.

worldArea is derived from zone. We could pass Datamine around everywhere instead
of duplicating information here, but that seems excessive

-}
type alias Address =
    { zone : String
    , addr : String
    , worldArea : Maybe WorldArea
    }


type alias AddressId =
    String


addressId : Address -> AddressId
addressId a =
    a.zone ++ "@" ++ a.addr


type Instance
    = MainMenu
    | Instance Address


type Builder
    = Empty
    | Connecting String
    | GenArea GenAreaData


type alias GenAreaData =
    { address : String, level : Int, worldAreaId : String }


type alias State =
    { val : Instance
    , joinedAt : Posix
    , next : Builder
    , afkVisit : List ( Posix, Posix )
    , afkStart : Maybe Posix
    , level : Maybe Int
    , position : Int
    }


init : Posix -> Int -> State
init t pos =
    -- initial-date is awkward, only Nothing on init, but we need to be able to tell the difference
    { val = MainMenu
    , joinedAt = t
    , next = Empty
    , afkVisit = []
    , afkStart = Nothing
    , position = pos
    , level = Nothing
    }


toAddress : Instance -> Maybe Address
toAddress instance =
    case instance of
        MainMenu ->
            Nothing

        Instance a ->
            Just a


unwrap : a -> (Address -> a) -> Instance -> a
unwrap default fn =
    toAddress >> Maybe.Extra.unwrap default fn


worldArea : Instance -> Maybe WorldArea
worldArea =
    toAddress >> Maybe.andThen .worldArea


zoneName : Instance -> Maybe String
zoneName =
    toAddress >> Maybe.map .zone


isTown : Instance -> Bool
isTown =
    -- No-zone is a town, since you're probably logged out and will log back in to town.
    -- Unknown-zone is *not* a town - towns are all known and accounted for, but non-map combat areas are excluded from my data.
    unwrap True (.worldArea >> Maybe.map (\w -> Datamine.isTown w || w.isHideout) >> Maybe.withDefault False)


isMap : Instance -> Bool
isMap =
    unwrap False (.worldArea >> Maybe.map Datamine.isMap >> Maybe.withDefault False)


duration : Posix -> State -> Millis
duration now state =
    Time.posixToMillis now - Time.posixToMillis state.joinedAt


offlineThreshold : Millis
offlineThreshold =
    -- TODO threshold should be configurable
    30 * Duration.minute


simulacrumOfflineThreshold : Millis
simulacrumOfflineThreshold =
    60 * Duration.minute


isSimulacrum : Instance -> Bool
isSimulacrum =
    worldArea >> Maybe.Extra.unwrap False (.id >> String.startsWith "AfflictionTown")


isDurationOffline : Millis -> Instance -> Bool
isDurationOffline dur instance =
    let
        threshold =
            if isSimulacrum instance then
                simulacrumOfflineThreshold

            else
                offlineThreshold
    in
    dur >= threshold


isOffline : Posix -> State -> Bool
isOffline now instance =
    isDurationOffline (duration now instance) instance.val


initOrUpdate : Datamine -> LogLine.Line -> Maybe State -> State
initOrUpdate datamine line instance =
    case instance of
        Just i ->
            update datamine line i

        Nothing ->
            init line.date line.position |> update datamine line


afkOff : Posix -> State -> State
afkOff afkEnd state =
    case state.afkStart of
        Nothing ->
            state

        Just afkStart ->
            { state
                | afkStart = Nothing
                , afkVisit = ( afkStart, afkEnd ) :: state.afkVisit
            }


update : Datamine -> LogLine.Line -> State -> State
update datamine line state =
    case line.info of
        -- it takes 2-3 loglines to build an instance:
        -- * "connecting to instance server (addr)"
        -- * (optional) "generating level N area"
        -- * "you have entered (zone)"
        -- we need both zone and addr, split across two lines, so it takes two steps.
        LogLine.ConnectingToInstanceServer addr ->
            -- step 1
            { state | next = Connecting addr, position = line.position }

        LogLine.GeneratingArea gen ->
            -- step 2 (optional)
            case state.next of
                Connecting addr ->
                    { state | next = GenArea { address = addr, level = gen.level, worldAreaId = gen.worldAreaId } }

                _ ->
                    state

        LogLine.YouHaveEntered zone_ ->
            -- step 3
            case state.next of
                GenArea gen ->
                    -- step 2
                    let
                        w =
                            Datamine.worldAreaFromName zone_ datamine
                    in
                    { state
                        | val =
                            Instance
                                { zone = zone_
                                , addr = gen.address
                                , worldArea = w
                                }
                        , level =
                            if Maybe.map .id w == Just gen.worldAreaId then
                                Just gen.level

                            else
                                Nothing
                        , joinedAt = line.date
                        , next = Empty
                        , afkStart = Nothing
                        , afkVisit = []
                    }

                Connecting addr ->
                    -- step 2
                    { state
                        | val =
                            Instance
                                { zone = zone_
                                , addr = addr
                                , worldArea = Datamine.worldAreaFromName zone_ datamine
                                }
                        , joinedAt = line.date
                        , next = Empty
                        , afkStart = Nothing
                        , afkVisit = []
                    }

                _ ->
                    state

        LogLine.Opening ->
            -- the game crashed and was just reopened, reset the instance
            init line.date line.position

        LogLine.AFKMode mode ->
            case ( mode, state.afkStart ) of
                ( True, Nothing ) ->
                    -- afk enabled, transition from disabled
                    { state | afkStart = Just line.date }

                ( False, Just _ ) ->
                    -- afk disabled, transition from enabled
                    afkOff line.date state

                _ ->
                    state

        -- Ignore all others, but explicitly list them for exhaustiveness checks
        LogLine.RitualFindClosestObject ->
            state

        LogLine.NPCSays _ ->
            state
