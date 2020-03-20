module View.Spreadsheet exposing (Cell(..), Sheet, posixToString, viewData)

import Dict exposing (Dict)
import Duration exposing (Millis)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Model exposing (Msg, OkModel)
import Route.Feature as Feature exposing (Feature)
import Time exposing (Posix)
import View.Home exposing (monthToString)


type Cell
    = CellString String
      -- | CellFormula String
    | CellDuration Millis
    | CellPosix Time.Zone Posix
    | CellBool Bool
    | CellInt Int
    | CellFloat Float
    | CellIcon String
    | CellEmpty


type alias Sheet =
    { title : String
    , headers : List (List String)
    , rows : List (List Cell)
    }


viewData : OkModel -> List MapRun -> Sheet
viewData model runs =
    { title = "Mapwatch: Data"
    , headers = [ viewDataHeaders model ]
    , rows =
        runs
            |> List.reverse
            |> List.indexedMap (viewDataRow model)
            |> List.reverse
    }


viewDataHeaders : OkModel -> List String
viewDataHeaders model =
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
    ]
        ++ (if Feature.isActive Feature.DeliriumEncounter model.query then
                [ "Delirium" ]

            else
                []
           )
        ++ [ "Zana"
           , "Vaal"
           , "Lab Trial"
           , "Abyssal Depths"
           ]


viewDataRow : OkModel -> Int -> MapRun -> List Cell
viewDataRow model i run =
    [ i + 1 |> CellInt
    , run.updatedAt |> CellPosix model.tz
    , run.address.worldArea |> Maybe.andThen (Datamine.imgSrc run) |> Maybe.Extra.unwrap CellEmpty CellIcon
    , run.address.zone |> CellString
    , run.address.worldArea |> Maybe.andThen .atlasRegion |> Maybe.withDefault "---" |> CellString
    , run.duration.all |> CellDuration
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
    ]
        ++ (if Feature.isActive Feature.DeliriumEncounter model.query then
                [ run |> viewNpc NpcId.delirium ]

            else
                []
           )
        ++ [ run |> viewSideArea Datamine.isMap
           , run |> viewSideArea .isVaalArea
           , run |> viewSideArea .isLabTrial
           , run |> viewSideArea .isAbyssalDepths |> (/=) CellEmpty |> CellBool
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
