module Mapwatch.MapRun.Trialmaster exposing (Outcome(..), State, duration, fromNpcs)

import Dict exposing (Dict)
import Duration exposing (Millis)
import List.Extra
import Mapwatch.Datamine as Datamine exposing (Datamine, UltimatumModifier)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Datamine.Trialmaster as DMTrialmaster exposing (Index)
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.LogLine as LogLine exposing (NPCSaysData)
import Mapwatch.RawMapRun as RawMapRun exposing (NpcEncounter, NpcEncounters, RawMapRun)
import Maybe.Extra


type alias State =
    { address : Address
    , outcome : Outcome
    , mods : List (Result String UltimatumModifier)
    , says : List String
    }


type Outcome
    = Won Millis
    | Lost Millis
    | Retreated Millis
    | Abandoned


duration : Outcome -> Maybe Millis
duration o =
    case o of
        Won d ->
            Just d

        Lost d ->
            Just d

        Retreated d ->
            Just d

        Abandoned ->
            Nothing


datamineOutcome : DMTrialmaster.Outcome -> Millis -> Outcome
datamineOutcome o =
    case o of
        DMTrialmaster.Won ->
            Won

        DMTrialmaster.Lost ->
            Lost

        DMTrialmaster.Retreated ->
            Retreated

        DMTrialmaster.Abandoned ->
            always Abandoned


fromNpcs : Datamine -> NpcEncounters -> List State
fromNpcs dm =
    Dict.get NpcId.trialmaster
        >> Maybe.withDefault []
        >> List.Extra.gatherEqualsBy .address
        >> List.map (\( head, tail ) -> head :: tail |> fromLines dm head.address)


fromLines : Datamine -> Address -> List NpcEncounter -> State
fromLines dm addr encounters =
    let
        outcomeEncounter : Maybe ( NpcEncounter, DMTrialmaster.Outcome )
        outcomeEncounter =
            encounters
                |> List.filterMap (\enc -> Dict.get enc.says.textId dm.ultimatumNpcTextIndex.outcomes |> Maybe.map (Tuple.pair enc))
                |> List.head

        modEncounters : List NpcEncounter
        modEncounters =
            encounters |> List.filter (.says >> .textId >> String.startsWith DMTrialmaster.roundPrefix)

        dur : Millis
        dur =
            let
                encs : List NpcEncounter
                encs =
                    -- ordered by date
                    List.reverse modEncounters ++ (outcomeEncounter |> Maybe.Extra.unwrap [] (Tuple.first >> List.singleton))
            in
            case encs of
                [] ->
                    0

                first :: rest ->
                    let
                        last =
                            rest |> List.Extra.last |> Maybe.withDefault first
                    in
                    Duration.diff { before = first.date, after = last.date }

        mods : List (Result String UltimatumModifier)
        mods =
            modEncounters
                |> List.map
                    (\enc ->
                        Dict.get enc.says.textId dm.ultimatumNpcTextIndex.modIds
                            |> Maybe.andThen (\modId -> Dict.get modId dm.ultimatumModifiersById)
                            |> Result.fromMaybe enc.says.textId
                    )
    in
    { address = addr
    , outcome =
        outcomeEncounter
            |> Maybe.map (Tuple.second >> datamineOutcome)
            |> Maybe.map (\o -> o dur)
            |> Maybe.withDefault Abandoned
    , mods = mods
    , says = encounters |> List.map (.says >> .raw) |> List.reverse
    }
