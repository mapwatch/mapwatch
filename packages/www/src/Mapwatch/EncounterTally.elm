module Mapwatch.EncounterTally exposing (EncounterTally, fromMapRuns)

import Dict exposing (Dict)
import Dict.Extra
import Duration exposing (Millis)
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Set exposing (Set)


type alias EncounterTally =
    { count : Int
    , vaalAreas : Int
    , labTrialsTotal : Int
    , labTrials : List ( String, Int )
    , abyssalDepths : Int
    , uniqueMaps : Int
    , blightedMaps : Int
    , delirium : Int
    , conquerors : Int
    , zana : Int
    , einhar : Int
    , alva : Int
    , niko : Int
    , jun : Int
    , cassia : Int
    , envoy : Int
    , maven : Int
    , oshabi : Int
    , heartOfTheGrove : Int
    }


empty : EncounterTally
empty =
    EncounterTally 0 0 0 [] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0



--add : EncounterTally -> EncounterTally -> EncounterTally
--add a b =
--    { vaalAreas = a.vaalAreas + b.vaalAreas
--    , labTrialsTotal = a.labTrialsTotal + b.labTrialsTotal
--    , labTrials =
--        a.labTrials
--            ++ b.labTrials
--            |> Dict.Extra.fromListDedupe (+)
--            |> Dict.toList
--    }


fromMapRuns : List MapRun -> EncounterTally
fromMapRuns runs =
    let
        maps : List Address
        maps =
            runs |> List.map .address

        sides : List ( Address, Millis )
        sides =
            runs |> List.concatMap (.sideAreas >> Dict.values)

        npcs : List NpcGroup
        npcs =
            runs |> List.concatMap (.npcSays >> Dict.keys)

        hearts =
            runs |> List.filter .isHeartOfTheGrove |> List.length
    in
    { empty
        | blightedMaps = runs |> List.filter .isBlightedMap |> List.length
        , heartOfTheGrove = hearts
        , uniqueMaps = maps |> List.filterMap .worldArea |> List.filter .isUniqueMapArea |> List.length
        , conquerors = runs |> List.filterMap .conqueror |> List.filter (\( conqueror, encounter ) -> encounter == Conqueror.Fight) |> List.length
        , count = List.length runs
    }
        |> tallyNpcs npcs
        |> (\t -> { t | oshabi = t.oshabi - hearts |> max 0 })
        |> tallySides sides


tallyNpcs : List NpcGroup -> EncounterTally -> EncounterTally
tallyNpcs npcs tally =
    let
        counts : Dict NpcGroup Int
        counts =
            npcs |> Dict.Extra.frequencies
    in
    { tally
        | einhar = Dict.get NpcId.einhar counts |> Maybe.withDefault 0
        , alva = Dict.get NpcId.alva counts |> Maybe.withDefault 0
        , niko = Dict.get NpcId.niko counts |> Maybe.withDefault 0
        , jun = Dict.get NpcId.betrayalGroup counts |> Maybe.withDefault 0
        , cassia = Dict.get NpcId.cassia counts |> Maybe.withDefault 0
        , delirium = Dict.get NpcId.delirium counts |> Maybe.withDefault 0
        , envoy = Dict.get NpcId.envoy counts |> Maybe.withDefault 0
        , maven = Dict.get NpcId.maven counts |> Maybe.withDefault 0
        , oshabi = Dict.get NpcId.oshabi counts |> Maybe.withDefault 0
    }


tallySides : List ( Address, Millis ) -> EncounterTally -> EncounterTally
tallySides durs tally =
    let
        addrs : List Address
        addrs =
            durs |> List.map Tuple.first

        worlds : List WorldArea
        worlds =
            addrs |> List.filterMap .worldArea

        trials : List Address
        trials =
            addrs |> List.filter (.worldArea >> Maybe.Extra.unwrap False .isLabTrial)
    in
    { tally
        | vaalAreas = worlds |> List.filter .isVaalArea |> List.length
        , labTrialsTotal = trials |> List.length
        , labTrials =
            trials
                |> List.map .zone
                |> Dict.Extra.frequencies
                |> Dict.toList
        , abyssalDepths = worlds |> List.filter .isAbyssalDepths |> List.length
        , uniqueMaps = tally.uniqueMaps + (worlds |> List.filter .isUniqueMapArea |> List.length)
        , zana = worlds |> List.filter .isMapArea |> List.length
    }
