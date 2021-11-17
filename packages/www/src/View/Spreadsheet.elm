module View.Spreadsheet exposing
    ( Cell(..)
    , Sheet
    , posixToString
    , viewEncounters
    , viewHistory
    , viewMaps
    )

import Dict exposing (Dict)
import Duration exposing (Millis)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.EncounterTally as EncounterTally exposing (EncounterTally)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Model exposing (Msg, OkModel)
import Page.Maps
import Route.Feature as Feature exposing (Feature)
import Set exposing (Set)
import Time exposing (Posix)
import View.Home exposing (monthToString)
import View.Icon


type Cell
    = CellString String
      -- | CellFormula String
    | CellDuration Millis
    | CellPosix Time.Zone Posix
    | CellBool Bool
    | CellInt Int
    | CellFloat Float
    | CellPercent Float
    | CellIcon String
    | CellEmpty


cellPercentInt : Int -> Int -> Cell
cellPercentInt n d =
    cellPercentFloat (toFloat n) (toFloat d)


cellPercentFloat : Float -> Float -> Cell
cellPercentFloat n d =
    n / d |> CellPercent


type alias Sheet =
    { title : String
    , headers : List (List String)
    , rows : List (List Cell)
    }


viewMaps : OkModel -> List MapRun -> Sheet
viewMaps model runs =
    let
        rows =
            runs
                |> Page.Maps.groupRuns model.mapwatch.datamine
                |> List.sortBy (.runs >> .num)
                |> List.reverse
    in
    { title = "Mapwatch: Maps"
    , headers = [ viewMapsHeaders ]
    , rows = rows |> List.indexedMap viewMapsRow
    }


viewMapsHeaders : List String
viewMapsHeaders =
    [ "Row"
    , "Icon"
    , "Name"
    , "Region"
    , "Tier"
    , "# Runs"
    , "Average"
    , "Best"
    , "Total"
    , "Avg Portals"

    -- this one goes last
    , "https://mapwatch.erosson.org"
    ]


viewMapsRow : Int -> Page.Maps.GroupedRuns -> List Cell
viewMapsRow i row =
    [ i + 1 |> CellInt
    , if row.worldArea.isLabyrinth then
        CellIcon View.Icon.labTrialUrl

      else
        row.worldArea
            |> Datamine.imgSrc { isBlightedMap = False, isGrandHeist = Nothing }
            |> Maybe.Extra.unwrap CellEmpty CellIcon
    , if row.worldArea.isLabyrinth then
        CellString "The Labyrinth"

      else
        row.name |> CellString
    , row.worldArea.atlasRegion |> Maybe.withDefault "---" |> CellString
    , Datamine.tier row.worldArea
        |> Maybe.Extra.unwrap CellEmpty CellInt
    , row.runs.num |> CellInt
    , row.runs.mean.duration.mainMap |> CellDuration
    , row.runs.best.mainMap |> Maybe.Extra.unwrap CellEmpty CellDuration
    , row.runs.total.duration.mainMap |> CellDuration
    , row.runs.mean.portals |> CellFloat
    ]


viewEncounters : OkModel -> List MapRun -> Sheet
viewEncounters model runs =
    let
        tally =
            EncounterTally.fromMapRuns runs
    in
    { title = "Mapwatch: Encounters"
    , headers = [ viewEncountersHeaders tally ]
    , rows = viewEncountersRows tally
    }


viewEncountersHeaders : EncounterTally -> List String
viewEncountersHeaders tally =
    [ "Row"
    , "Encounter"
    , "#"
    , "%"

    -- this one goes last
    , "https://mapwatch.erosson.org"
    ]


viewEncountersRows : EncounterTally -> List (List Cell)
viewEncountersRows tally =
    [ { count = tally.count, label = "All maps" }
    , { count = tally.abyssalDepths, label = "Abyssal Depths" }
    , { count = tally.vaalAreas, label = "Vaal side areas" }
    , { count = tally.uniqueMaps, label = "Unique Maps" }
    , { count = tally.labTrialsTotal, label = "(" ++ (String.fromInt <| List.length tally.labTrials) ++ "/6) Labyrinth Trials" }
    , { count = tally.blightedMaps, label = "Blighted Maps" }
    , { count = tally.conquerors, label = "Conqueror Fights" }
    , { count = tally.zana, label = "Zana" }
    , { count = tally.einhar, label = "Einhar" }
    , { count = tally.alva, label = "Alva" }
    , { count = tally.niko, label = "Niko" }
    , { count = tally.jun, label = "Jun" }
    , { count = tally.delirium, label = "Delirium" }
    , { count = tally.oshabi, label = "Oshabi (INCOMPLETE)" }
    , { count = tally.heartOfTheGrove, label = "Heart of the Grove" }
    , { count = tally.grandHeists, label = "Grand Heists" }
    , { count = tally.heistContracts, label = "Heist Contracts" }
    , { count = tally.nonHeists, label = "Non-Heist Maps" }
    , { count = tally.labyrinths, label = "The Labyrinth" }
    , { count = tally.envoy, label = "The Envoy" }
    , { count = tally.maven, label = "The Maven" }
    , { count = tally.sirusInvasions, label = "Sirus Invasions" }
    , { count = tally.trialmaster, label = "The Trialmaster" }
    , { count = tally.gwennen, label = "Gwennen, the Gambler" }
    , { count = tally.tujen, label = "Tujen, the Haggler" }
    , { count = tally.rog, label = "Rog, the Dealer" }
    , { count = tally.dannig, label = "Dannig, Warrior Skald" }
    , { count = tally.ritual, label = "Ritual" }
    ]
        |> List.sortBy .count
        |> List.reverse
        |> List.indexedMap Tuple.pair
        |> List.map
            (\( i, row ) ->
                [ CellInt i
                , CellString row.label
                , CellInt row.count
                , cellPercentInt row.count tally.count
                ]
            )


viewHistory : OkModel -> List MapRun -> Sheet
viewHistory model runs =
    { title = "Mapwatch: History"
    , headers = [ viewHistoryHeaders model ]
    , rows =
        runs
            |> List.reverse
            |> List.indexedMap (viewHistoryRow model)
            |> List.reverse
    }


viewHistoryHeaders : OkModel -> List String
viewHistoryHeaders model =
    [ "Row"
    , "Date"
    , "Icon"
    , "Map"
    , "Region"
    , "Duration"
    , "Map"
    , "Town"
    , "Sides"
    , "Portals"

    -- denormalizing all the side areas/npcs below isn't ideal - but it's easier
    -- for most users to work without foreign keys, and it lets them copy-paste
    -- it all in one shot
    , "Baran"
    , "Veritania"
    , "Al-Hezmin"
    , "Drox"
    , "Einhar"
    , "Alva"
    , "Niko"
    , "Jun"
    , "Cassia"
    , "Legion General"
    , "Delirium"
    , "Oshabi"
    , "Heart of the Grove"
    , "Envoy"
    , "Maven"
    , "Zana"
    , "Vaal"
    , "Lab Trial"
    , "Abyssal Depths"
    , "Ritual"
    , "Abandoned Map Run"

    -- this one goes last
    , "https://mapwatch.erosson.org"
    ]


viewHistoryRow : OkModel -> Int -> MapRun -> List Cell
viewHistoryRow model i run =
    [ i + 1 |> CellInt
    , run.updatedAt |> CellPosix model.tz
    , run.address.worldArea |> Maybe.andThen (Datamine.imgSrc run) |> Maybe.Extra.unwrap CellEmpty CellIcon
    , run.address.zone |> CellString
    , run.address.worldArea |> Maybe.andThen .atlasRegion |> Maybe.withDefault "---" |> CellString
    , if run.isAbandoned then
        "???" |> CellString

      else
        run.duration.all |> CellDuration
    , run.duration.mainMap |> CellDuration
    , run.duration.town |> CellDuration
    , run.duration.sides |> CellDuration
    , run.portals |> CellInt
    , run |> viewConqueror Conqueror.Baran
    , run |> viewConqueror Conqueror.Veritania
    , run |> viewConqueror Conqueror.AlHezmin
    , run |> viewConqueror Conqueror.Drox
    , run |> viewNpc NpcId.einhar
    , run |> viewNpc NpcId.alva
    , run |> viewNpc NpcId.niko
    , run |> viewNpc NpcId.betrayalGroup
    , run |> viewNpc NpcId.cassia
    , run |> viewNpc NpcId.legionGeneralGroup
    , run |> viewNpc NpcId.delirium
    , run |> viewNpc NpcId.oshabi
    , run.isHeartOfTheGrove |> CellBool
    , run |> viewNpc NpcId.envoy
    , run |> viewNpc NpcId.maven
    , run |> viewSideArea Datamine.isZanaMap
    , run |> viewSideArea .isVaalArea
    , run |> viewSideArea .isLabTrial
    , run |> viewSideArea .isAbyssalDepths |> (/=) CellEmpty |> CellBool
    , run.rituals |> CellInt
    , CellBool run.isAbandoned
    ]


viewSideArea : (WorldArea -> Bool) -> MapRun -> Cell
viewSideArea pred =
    .sideAreas
        >> Dict.values
        >> List.map Tuple.first
        >> List.filter (\a -> a.worldArea |> Maybe.Extra.unwrap False pred)
        >> List.head
        >> Maybe.Extra.unwrap CellEmpty (.zone >> CellString)


viewNpc : NpcId -> MapRun -> Cell
viewNpc npcId =
    .npcSays >> Dict.member npcId >> CellBool


viewConqueror : Conqueror.Id -> MapRun -> Cell
viewConqueror cid run =
    case run.conqueror of
        Just ( id, encounter ) ->
            if id == cid then
                case encounter of
                    Conqueror.Fight ->
                        CellString "fight"

                    Conqueror.Taunt n ->
                        CellString <| "taunt " ++ String.fromInt n

            else
                CellEmpty

        _ ->
            CellEmpty


{-| A format that spreadsheets can parse well, with more detail than the mapwatch ui
-}
posixToString : Time.Zone -> Posix -> String
posixToString tz d =
    ([ Time.toYear tz d |> String.fromInt
     , Time.toMonth tz d |> monthToString
     , Time.toDay tz d |> String.fromInt |> String.padLeft 2 '0'
     ]
        |> String.join "/"
    )
        ++ " "
        ++ ([ Time.toHour tz d
            , Time.toMinute tz d
            , Time.toSecond tz d
            ]
                |> List.map (String.fromInt >> String.padLeft 2 '0')
                |> String.join ":"
           )
