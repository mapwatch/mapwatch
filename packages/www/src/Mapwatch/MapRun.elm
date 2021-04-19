module Mapwatch.MapRun exposing
    ( Aggregate
    , Durations
    , MapRun
    , TrialmasterResult(..)
    , TrialmasterState
    , aggregate
    , fromRaw
    )

{-| Run data optimized for display, analysis, and (later) serialization.

Frozen; cannot be modified. Lots of redundancy. Use RawMapRun for updates and log processing.

-}

import Dict exposing (Dict)
import Duration exposing (Millis)
import List.Extra
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Mapwatch.LogLine as LogLine exposing (NPCSaysData)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.Visit as Visit exposing (Visit)
import Maybe.Extra
import Set exposing (Set)
import Time exposing (Posix)


type alias MapRun =
    { address : Address
    , startedAt : Posix
    , updatedAt : Posix
    , portals : Int

    -- durations
    , sideAreas : Dict AddressId ( Address, Millis )
    , duration : Durations
    , isAbandoned : Bool

    -- npc interactions
    , isBlightedMap : Bool
    , conqueror : Maybe ( Conqueror.Id, Conqueror.Encounter )
    , npcSays : Dict NpcGroup (List String)
    , heistNpcs : Set NpcId
    , rootNpcs : Set NpcId
    , trialmaster : Maybe TrialmasterState

    -- isGrandHeist: True, False (heist contract), or Null (not a heist)
    , isGrandHeist : Maybe Bool
    , isHeartOfTheGrove : Bool
    }


type alias AddressId =
    String


type alias TrialmasterState =
    { rounds : Int, result : TrialmasterResult }


type TrialmasterResult
    = TrialmasterWin
    | TrialmasterLoss
    | TrialmasterFled
    | TrialmasterResultUnknown


type alias Durations =
    { all : Millis
    , town : Millis
    , mainMap : Millis
    , sides : Millis
    , notTown : Millis
    }


type alias Aggregate =
    { mean : { duration : Durations, portals : Float }
    , total : { duration : Durations, portals : Int }
    , best : { all : Maybe Millis, mainMap : Maybe Millis }
    , num : Int
    }


aggregate : List MapRun -> Aggregate
aggregate runs0 =
    let
        runs =
            runs0 |> List.filter (\r -> not r.isAbandoned)

        durations =
            List.map .duration runs

        num =
            List.length runs

        nmean =
            max 1 num

        totalDuration =
            { all = durations |> List.map .all |> List.sum
            , town = durations |> List.map .town |> List.sum
            , mainMap = durations |> List.map .mainMap |> List.sum
            , sides = durations |> List.map .sides |> List.sum
            , notTown = durations |> List.map .notTown |> List.sum
            }

        portals =
            runs |> List.map .portals |> List.sum
    in
    { mean =
        { portals = toFloat portals / toFloat nmean
        , duration =
            { all = totalDuration.all // nmean
            , town = totalDuration.town // nmean
            , mainMap = totalDuration.mainMap // nmean
            , sides = totalDuration.sides // nmean
            , notTown = totalDuration.notTown // nmean
            }
        }
    , total =
        { portals = portals
        , duration = totalDuration
        }
    , best =
        { all = durations |> List.map .all |> List.minimum
        , mainMap = durations |> List.map .mainMap |> List.minimum
        }
    , num = num
    }


fromRaw : Datamine -> RawMapRun -> MapRun
fromRaw dm raw =
    let
        -- durations by instance. includes time spent with the game closed.
        idurs : List ( Instance, Millis )
        idurs =
            durationPerInstance raw

        -- durations by address. ignores time where the game is closed, but more convenient.
        adurs : List ( Address, Millis )
        adurs =
            idurs |> List.filterMap addressDuration

        sideDurs : List ( Address, Millis )
        sideDurs =
            adurs |> List.filter (Tuple.first >> isSideArea raw)

        all : Millis
        all =
            idurs
                |> List.map Tuple.second
                |> List.sum

        town : Millis
        town =
            idurs
                |> List.filter (Tuple.first >> Instance.isTown)
                |> List.map Tuple.second
                |> List.sum

        mainMap : Millis
        mainMap =
            adurs
                |> List.filter (Tuple.first >> (==) raw.address)
                |> List.map Tuple.second
                |> List.sum

        addr : Address
        addr =
            toMapRunAddress dm raw

        heist =
            heistNpcs raw
    in
    { address = addr
    , startedAt = raw.startedAt
    , updatedAt = RawMapRun.updatedAt raw
    , portals = raw.portals
    , isAbandoned = raw.isAbandoned
    , isBlightedMap = isBlightedMap raw
    , heistNpcs = heist
    , rootNpcs = rootNpcs raw
    , isGrandHeist =
        if Set.isEmpty heist then
            -- not a heist!
            Nothing

        else
            Just <| Set.size heist > 1
    , isHeartOfTheGrove = isHeartOfTheGrove raw
    , conqueror = conquerorEncounterFromNpcs raw.npcSays
    , trialmaster = trialmasterFromNpcs raw.npcSays

    -- List.reverse: RawMapRun prepends the newest runs to the list, because that's
    -- how linked lists work. We want to view oldest-first, not newest-first.
    , npcSays = raw.npcSays |> Dict.map (\npcId -> List.map (Tuple.first >> .raw) >> List.reverse)
    , sideAreas =
        sideDurs
            |> List.map (\( a, d ) -> ( Instance.addressId a, ( a, d ) ))
            |> Dict.fromList
    , duration =
        { all = all
        , town = town
        , notTown = all - town
        , mainMap = mainMap
        , sides = sideDurs |> List.map Tuple.second |> List.sum
        }
    }


toMapRunAddress : Datamine -> RawMapRun -> Address
toMapRunAddress dm ({ address } as raw) =
    case address.worldArea of
        Nothing ->
            address

        Just w ->
            -- The overwhelming majority of the time, the worldarea is based solely on its name, unchanged.
            -- There are a few special cases, though:
            if w.id == "MapWorldsShapersRealm" || w.id == "MapWorldsElderArenaUber" then
                -- Shaper and Uber-Elder maps are both named "The Shaper's Realm", ambiguous.
                -- Use the shaper's voice lines to distinguish them.
                -- https://github.com/mapwatch/mapwatch/issues/55
                let
                    shaperSays =
                        Dict.get NpcId.shaper raw.npcSays
                            |> Maybe.withDefault []
                            |> List.map (Tuple.first >> .textId)
                            |> List.filter ((/=) "")
                in
                if List.any ((==) "ShaperMapShapersRealm") shaperSays then
                    { address | worldArea = Dict.get "MapWorldsShapersRealm" dm.worldAreasById }

                else if List.any ((==) "ShaperUberElderIntro") shaperSays then
                    { address
                        | worldArea = Dict.get "MapWorldsElderArenaUber" dm.worldAreasById

                        -- Distinguish the display name so users can easily tell them apart
                        , zone = address.zone ++ ": Uber Elder"
                    }

                else
                    address

            else if w.id == "MapWorldsLaboratory" || String.startsWith "HeistDungeon" w.id then
                -- There's a Laboratory map and a Laboratory heist.
                -- Use Heist rogue voicelines to distinguish them.
                -- https://github.com/mapwatch/mapwatch/issues/124
                if raw |> heistNpcs |> Set.isEmpty then
                    { address | worldArea = Dict.get "MapWorldsLaboratory" dm.worldAreasById }

                else
                    { address | worldArea = Dict.get "HeistDungeon1" dm.worldAreasById }

            else if w.isLabyrinth then
                -- Treat the Labyrinth as a single worldArea. This isn't accurate -
                -- it's a series of different worldAreas - but faking a consistent
                -- lab worldArea simplifies so much.
                { address | worldArea = Just labyrinthWorldArea, zone = "The Labyrinth" }

            else
                address


labyrinthWorldArea : WorldArea
labyrinthWorldArea =
    { id = "__mapwatch:TheLabyrinth"
    , isLabyrinth = True
    , itemVisualId = Just "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLabyrinth.png?scale=1"

    --
    , isTown = False
    , isHideout = False
    , isMapArea = False
    , isUniqueMapArea = False
    , isVaalArea = False
    , isLabTrial = False
    , isAbyssalDepths = False
    , atlasRegion = Nothing
    , tiers = Nothing
    }


trialmasterFromNpcs : RawMapRun.NpcEncounters -> Maybe TrialmasterState
trialmasterFromNpcs =
    Dict.get NpcId.trialmaster
        >> Maybe.map (List.map Tuple.first >> trialmasterFromLines)


trialmasterFromLines : List LogLine.NPCSaysData -> TrialmasterState
trialmasterFromLines lines =
    let
        ids : List String
        ids =
            lines |> List.map .textId |> Debug.log "trialmaster-ids"
    in
    { rounds =
        List.Extra.count (String.startsWith "TrialmasterChallengeChoiceMade") ids
    , result =
        if ids |> List.Extra.find (String.startsWith "TrialmasterMoodPlayerWon") |> Maybe.Extra.isJust then
            TrialmasterWin

        else if ids |> List.Extra.find (String.startsWith "TrialmasterMoodPlayerLost") |> Maybe.Extra.isJust then
            TrialmasterLoss

        else if
            (ids |> List.Extra.find (String.startsWith "TrialmasterPlayerTookReward") |> Maybe.Extra.isJust)
                || (ids |> List.Extra.find (String.startsWith "TrialmasterTutorialStop") |> Maybe.Extra.isJust)
        then
            TrialmasterFled

        else
            TrialmasterResultUnknown
    }


conquerorEncounterFromNpcs : RawMapRun.NpcEncounters -> Maybe ( Conqueror.Id, Conqueror.Encounter )
conquerorEncounterFromNpcs npcSays =
    Conqueror.ids
        |> List.filterMap
            (\id ->
                Dict.get (Conqueror.npcFromId id) npcSays
                    |> Maybe.andThen (List.map (Tuple.first >> .textId) >> Conqueror.encounter id)
                    |> Maybe.map (Tuple.pair id)
            )
        |> List.head


{-| If Cassia announces 8 new lanes and there are no other npcs, it must be a blighted map
-}
isBlightedMap : RawMapRun -> Bool
isBlightedMap run =
    let
        newLanes =
            run.npcSays
                |> Dict.get NpcId.cassia
                |> Maybe.withDefault []
                |> List.filter (Tuple.first >> .textId >> String.startsWith "CassiaNewLane")
    in
    Dict.size run.npcSays == 1 && List.length newLanes >= 8


{-| If Oshabi uses one of her boss voicelines, this is Heart of the Grove fight, not a regular Harvest
-}
isHeartOfTheGrove : RawMapRun -> Bool
isHeartOfTheGrove =
    .npcSays
        >> Dict.get NpcId.oshabi
        >> Maybe.withDefault []
        >> List.filter (Tuple.first >> .textId >> (\t -> String.startsWith "HarvestBoss" t || String.startsWith "HarvestReBoss" t))
        >> (\l -> List.length l > 0)


{-| Ignore Heist rogues that don't use any skills.

This happens with in-town chatter before they're hired.

-}
heistNpcs : RawMapRun -> Set NpcId
heistNpcs =
    .npcSays
        >> Dict.filter (\k _ -> Set.member k NpcId.heistNpcs)
        >> Dict.map (\_ -> List.filter (\( t, _ ) -> t.textId /= ""))
        >> Dict.filter (\_ -> List.isEmpty >> not)
        >> Dict.keys
        >> Set.fromList


{-| NpcIds encountered in the root map. NpcIds not in this list must've been encountered in a side area, like a Zana map.
-}
rootNpcs : RawMapRun -> Set NpcId
rootNpcs raw =
    raw.npcSays
        |> Dict.toList
        |> List.filter
            (Tuple.second
                >> List.filter (\( addr, instance ) -> Instance.Instance raw.address == instance)
                >> List.isEmpty
                >> not
            )
        |> List.map Tuple.first
        |> Set.fromList


durationPerInstance : RawMapRun -> List ( Instance, Millis )
durationPerInstance { visits } =
    let
        instanceToZoneKey instance_ =
            case instance_ of
                Instance.Instance i ->
                    i.zone

                Instance.MainMenu ->
                    "(none)"

        updateDurDict instance_ duration_ val0 =
            val0
                |> Maybe.withDefault ( instance_, 0 )
                |> Tuple.mapSecond ((+) duration_)
                |> Just

        foldDurs ( instance_, duration_ ) dict =
            Dict.update (instanceToZoneKey instance_) (updateDurDict instance_ duration_) dict
    in
    visits
        |> List.map (\v -> ( v.instance, Visit.duration v ))
        |> List.foldl foldDurs Dict.empty
        |> Dict.values


isSideArea : RawMapRun -> Address -> Bool
isSideArea raw addr =
    raw.address /= addr && not (Instance.isTown (Instance.Instance addr))


addressDuration : ( Instance, Millis ) -> Maybe ( Address, Millis )
addressDuration ( i_, d ) =
    case i_ of
        Instance.Instance i ->
            Just ( i, d )

        Instance.MainMenu ->
            Nothing
