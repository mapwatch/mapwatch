module View.HistoryTSV exposing (view, viewHeader, viewRow)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Model exposing (Msg(..), OkModel)
import View.History
import View.Home
import View.Nav
import View.Setup


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Setup.view model
        , viewBody model
        ]


viewBody : OkModel -> Html Msg
viewBody model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            View.Home.viewProgress p

        Mapwatch.Ready p ->
            viewMain model


viewMain : OkModel -> Html Msg
viewMain model =
    div []
        [ p []
            [ text "Copy and paste the "
            , b [] [ text "Tab-Separated Values" ]
            , text " below into your favorite spreadsheet application."
            ]
        , textarea [ readonly True, rows 40, cols 100 ]
            [ model
                |> View.History.listRuns
                |> List.reverse
                |> List.indexedMap (viewRow model)
                |> List.reverse
                |> (++) [ viewHeader ]
                |> List.map
                    (List.map
                        (String.replace "\\" "\\\\"
                            >> String.replace "\t" "\\t"
                        )
                        >> String.join "\t"
                    )
                |> String.join "\n"
                |> text
            ]
        ]


viewHeader : List String
viewHeader =
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
    , "Zana"
    , "Vaal"
    , "Lab Trial"
    , "Abyssal Depths"
    ]


viewRow : OkModel -> Int -> MapRun -> List String
viewRow model i run =
    [ String.fromInt (i + 1)
    , View.Home.posixToString model.tz run.updatedAt
    , run.address.worldArea |> Maybe.andThen (Datamine.imgSrc run) |> Maybe.Extra.unwrap "" (\img -> "=IMAGE(\"" ++ img ++ "\")")
    , run.address.zone
    , run.address.worldArea |> Maybe.andThen .atlasRegion |> Maybe.withDefault "---"
    , "'" ++ View.Home.formatDuration run.duration.all
    , "'" ++ View.Home.formatDuration run.duration.mainMap
    , "'" ++ View.Home.formatDuration run.duration.town
    , "'" ++ View.Home.formatDuration run.duration.sides
    , String.fromInt run.portals
    , viewConqueror Conqueror.Baran run
    , viewConqueror Conqueror.Veritania run
    , viewConqueror Conqueror.AlHezmin run
    , viewConqueror Conqueror.Drox run
    , viewNpc NpcId.einhar run
    , viewNpc NpcId.alva run
    , viewNpc NpcId.niko run
    , viewNpc NpcId.jun run
    , viewNpc NpcId.cassia run
    , viewSideArea Datamine.isMap run
    , viewSideArea .isVaalArea run
    , viewSideArea .isLabTrial run
    , if viewSideArea .isAbyssalDepths run == "" then
        ""

      else
        "TRUE"
    ]


viewSideArea : (WorldArea -> Bool) -> MapRun -> String
viewSideArea pred =
    .sideAreas
        >> Dict.values
        >> List.map Tuple.first
        >> List.filter (\a -> a.worldArea |> Maybe.Extra.unwrap False pred)
        >> List.head
        >> Maybe.Extra.unwrap "" .zone


viewNpc : NpcId -> MapRun -> String
viewNpc npcId run =
    if Dict.member npcId run.npcSays then
        "TRUE"

    else
        ""


viewConqueror : Conqueror.Id -> MapRun -> String
viewConqueror cid run =
    case run.conqueror of
        Just ( id, encounter ) ->
            if id == cid then
                case encounter of
                    Conqueror.Fight ->
                        "fight"

                    Conqueror.Taunt n ->
                        "taunt " ++ String.fromInt n

            else
                ""

        _ ->
            ""
