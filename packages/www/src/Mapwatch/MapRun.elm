module Mapwatch.MapRun exposing
    ( Aggregate
    , Durations
    , MapRun
    , aggregate
    , fromRaw
    )

{-| Run data optimized for display, analysis, and (later) serialization.

Frozen; cannot be modified. Lots of redundancy. Use RawMapRun for updates and log processing.

-}

import Dict exposing (Dict)
import Duration exposing (Millis)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
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

    -- npc interactions
    , isBlightedMap : Bool
    , conqueror : Maybe ( Conqueror.Id, Conqueror.Encounter )
    , npcSays : Dict NpcId (List String)
    }


type alias AddressId =
    String


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
aggregate runs =
    let
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


fromRaw : RawMapRun -> MapRun
fromRaw raw =
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
    in
    { address = raw.address
    , startedAt = raw.startedAt
    , updatedAt = RawMapRun.updatedAt raw
    , portals = raw.portals
    , isBlightedMap = isBlightedMap raw
    , conqueror = conquerorEncounterFromNpcs raw.npcSays

    -- List.reverse: RawMapRun prepends the newest runs to the list, because that's
    -- how linked lists work. We want to view oldest-first, not newest-first.
    , npcSays = raw.npcSays |> Dict.map (\npcId -> List.map .raw >> List.reverse)
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


conquerorEncounterFromNpcs : RawMapRun.NpcEncounters -> Maybe ( Conqueror.Id, Conqueror.Encounter )
conquerorEncounterFromNpcs npcSays =
    Conqueror.ids
        |> List.filterMap
            (\id ->
                Dict.get (Conqueror.npcFromId id) npcSays
                    |> Maybe.andThen (List.map .textId >> Conqueror.encounter id)
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
                |> List.filter (.textId >> String.startsWith "CassiaNewLane")
    in
    Dict.size run.npcSays == 1 && List.length newLanes >= 8


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
