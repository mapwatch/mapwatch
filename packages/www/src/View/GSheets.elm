module View.GSheets exposing (view)

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
import Model exposing (Msg, OkModel)
import RemoteData exposing (RemoteData)
import Route.Feature as Feature exposing (Feature)
import View.History
import View.HistoryTSV
import View.Home
import View.Icon
import View.Nav
import View.NotFound
import View.Setup


view : OkModel -> Html Msg
view model =
    if Feature.isActive Feature.GSheets model.query then
        div [ class "main" ]
            [ View.Home.viewHeader model
            , View.Nav.view model
            , View.Setup.view model
            , viewBody model
            ]

    else
        View.NotFound.view model


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
    case model.gsheets of
        RemoteData.NotAsked ->
            div []
                [ p [] [ text "Login to your Google account below to create a spreadsheet with your Mapwatch data." ]
                , button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
                ]

        RemoteData.Loading ->
            div []
                [ button [ disabled True ] [ View.Icon.fasPulse "spinner", text " Login to Google Sheets" ]
                ]

        RemoteData.Failure err ->
            div []
                [ button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
                , pre [] [ text err ]
                ]

        RemoteData.Success gsheets ->
            let
                runs =
                    View.History.listRuns model
            in
            div []
                [ div []
                    [ button [ onClick Model.GSheetsLogout ]
                        [ text "Logout of Google Sheets" ]
                    ]
                , div []
                    [ case ( gsheets.url, model.settings.spreadsheetId ) of
                        ( RemoteData.Loading, _ ) ->
                            button [ disabled True ]
                                [ View.Icon.fasPulse "spinner", text <| " Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]

                        ( _, Nothing ) ->
                            button [ onClick <| gsheetsWrite model runs Nothing ]
                                [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to a new spreadsheet" ]

                        ( _, Just id ) ->
                            button [ onClick <| gsheetsWrite model runs (Just id) ]
                                [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]
                    , input
                        [ type_ "text"
                        , value <| Maybe.withDefault "" model.settings.spreadsheetId
                        , onInput Model.InputSpreadsheetId
                        ]
                        []
                    ]
                , case gsheets.url of
                    RemoteData.NotAsked ->
                        div [] []

                    RemoteData.Loading ->
                        div [] [ View.Icon.fasPulse "spinner" ]

                    RemoteData.Failure err ->
                        div [] [ pre [] [ text err ] ]

                    RemoteData.Success url ->
                        div []
                            [ p []
                                [ text "Export successful! "
                                , a [ target "_blank", href url ] [ text "View your spreadsheet." ]
                                ]
                            ]
                ]


gsheetsWrite : OkModel -> List MapRun -> Maybe String -> Msg
gsheetsWrite model runs spreadsheetId =
    Model.GSheetsWrite
        { spreadsheetId = spreadsheetId
        , headers = View.HistoryTSV.viewHeader
        , rows =
            runs
                |> List.reverse
                |> List.indexedMap (View.HistoryTSV.viewRow model)
                |> List.reverse
        }
