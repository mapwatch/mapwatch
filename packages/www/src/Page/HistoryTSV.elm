module Page.HistoryTSV exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Model exposing (Msg, OkModel)
import Page.History
import View.Home
import View.Nav
import View.Setup
import View.Spreadsheet as Spreadsheet


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
    let
        runs =
            Page.History.listRuns model
    in
    div []
        [ p [ L.historyTsvHeader ] []
        , div [ L.historyTsvHistory ] []
        , textarea [ readonly True, rows 40, cols 100 ] [ viewSheet <| Spreadsheet.viewHistory model runs ]
        , div [ L.historyTsvMaps ] []
        , textarea [ readonly True, rows 40, cols 100 ] [ viewSheet <| Spreadsheet.viewMaps model runs ]
        , div [ L.historyTsvEncounters ] []
        , textarea [ readonly True, rows 40, cols 100 ] [ viewSheet <| Spreadsheet.viewEncounters model runs ]
        ]


viewSheet : Spreadsheet.Sheet -> Html msg
viewSheet sheet =
    sheet.headers
        ++ (sheet.rows |> List.map (List.map viewCell))
        |> List.map (String.join "\t")
        |> String.join "\n"
        |> text


viewCell : Spreadsheet.Cell -> String
viewCell c =
    esc <|
        case c of
            Spreadsheet.CellEmpty ->
                ""

            Spreadsheet.CellString s ->
                "'" ++ s

            Spreadsheet.CellDuration d ->
                "'" ++ View.Home.formatDuration d

            Spreadsheet.CellPosix tz t ->
                Spreadsheet.posixToString tz t

            Spreadsheet.CellBool b ->
                if b then
                    "TRUE"

                else
                    ""

            Spreadsheet.CellInt n ->
                String.fromInt n

            Spreadsheet.CellFloat n ->
                String.fromFloat n

            Spreadsheet.CellPercent n ->
                (100 * n |> String.fromFloat |> String.left 5) ++ "%"

            Spreadsheet.CellIcon src ->
                "=IMAGE(\"" ++ src ++ "\")"


esc : String -> String
esc =
    String.replace "\\" "\\\\" >> String.replace "\t" "\\t"
