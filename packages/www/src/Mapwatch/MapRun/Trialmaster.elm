module Mapwatch.MapRun.Trialmaster exposing (Outcome(..), State, fromNpcs)

import Dict exposing (Dict)
import List.Extra
import Mapwatch.Datamine as Datamine exposing (Datamine, UltimatumModifier)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Datamine.Trialmaster as DMTrialmaster exposing (Index)
import Mapwatch.LogLine as LogLine exposing (NPCSaysData)
import Mapwatch.RawMapRun as RawMapRun exposing (NpcEncounters, RawMapRun)
import Maybe.Extra


type alias State =
    { outcome : Outcome
    , mods : List (Result String UltimatumModifier)
    }


type Outcome
    = Won
    | Lost
    | Retreated
    | Abandoned


datamineOutcome : DMTrialmaster.Outcome -> Outcome
datamineOutcome o =
    case o of
        DMTrialmaster.Won ->
            Won

        DMTrialmaster.Lost ->
            Lost

        DMTrialmaster.Retreated ->
            Retreated

        DMTrialmaster.Abandoned ->
            Abandoned


fromNpcs : Datamine -> NpcEncounters -> Maybe State
fromNpcs dm =
    Dict.get NpcId.trialmaster
        >> Maybe.map (List.map (Tuple.first >> .textId) >> fromLines dm)


fromLines : Datamine -> List String -> State
fromLines dm npcTextIds =
    let
        modNpcTextIds =
            npcTextIds |> List.filter (String.startsWith DMTrialmaster.roundPrefix)

        mods : List (Result String UltimatumModifier)
        mods =
            modNpcTextIds
                |> List.map
                    (\npcTextId ->
                        Dict.get npcTextId dm.ultimatumNpcTextIndex.modIds
                            |> Maybe.andThen (\modId -> Dict.get modId dm.ultimatumModifiersById)
                            |> Result.fromMaybe npcTextId
                    )
    in
    { outcome =
        npcTextIds
            |> List.filterMap (\id -> Dict.get id dm.ultimatumNpcTextIndex.outcomes)
            |> List.head
            |> Maybe.map datamineOutcome
            |> Maybe.withDefault Abandoned
    , mods = mods
    }
