module Page.LogSlice exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Model exposing (Msg, OkModel)
import Page.History
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Url.Builder
import View.Home
import View.Nav
import View.Setup


view : Int -> Int -> OkModel -> Html Msg
view posStart posEnd model =
    div [ class "main", style "width" "100%" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Setup.view model
        , viewBody posStart posEnd model
        ]


viewBody : Int -> Int -> OkModel -> Html Msg
viewBody posStart posEnd model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            View.Home.viewProgress p

        Mapwatch.Ready _ ->
            case model.logSlicePage of
                RemoteData.NotAsked ->
                    div [] []

                RemoteData.Loading ->
                    div [] [ text "loading....." ]

                RemoteData.Failure err ->
                    pre [ style "color" "red" ] [ text err ]

                RemoteData.Success slice ->
                    let
                        -- escapedLog =
                        -- slice.log
                        -- |> String.replace "&" "&amp;"
                        -- |> String.replace "<" "&lt;"
                        bugLink =
                            "https://github.com/mapwatch/mapwatch/issues/new"

                        -- "url too long" error, booooo
                        -- ++ Url.Builder.toQuery [ Url.Builder.string "body" <| "<details><summary>Client.txt log snippet</summary><pre>" ++ escapedLog ++ "</pre></details>" ]
                    in
                    div []
                        [ h3 [] [ text "Log Snippet" ]
                        , table [ class "timer history" ]
                            [ slice.model.runs
                                |> List.map (Page.History.viewHistoryRun model { showDate = True, loadedAt = model.loadedAt } (always Nothing))
                                |> List.concat
                                |> tbody []
                            ]
                        , div [] <|
                            if List.isEmpty slice.model.runs then
                                [ p [] [ text "This excerpt from your ", code [] [ text "client.txt" ], text " file generated no complete Mapwatch runs." ]
                                ]

                            else
                                [ p []
                                    [ text "Mapwatch generated this using the excerpt from your "
                                    , code [] [ text "client.txt" ]
                                    , text " file seen below."
                                    ]
                                ]
                        , p []
                            [ text "Anything uninteresting to Mapwatch has been removed, including chat and IP addresses."
                            , br [] []
                            , b [] [ text "You can copy and share this text with others." ]
                            ]
                        , textarea [ readonly True, style "min-height" "20em", style "width" "100%" ] [ text slice.filteredLog ]
                        , details []
                            [ summary [] [ text "Click for the unfiltered log excerpt, including chat, whispers, and IP addresses." ]
                            , div [] [ b [] [ text "Do not share this with the public." ] ]
                            , div []
                                [ small []
                                    [ text "One exception: if you're "
                                    , a [ target "_blank", href bugLink ] [ text "reporting a bug in Mapwatch" ]
                                    , text ", sharing this with the Mapwatch developer is very helpful."
                                    ]
                                ]
                            , textarea [ readonly True, style "min-height" "20em", style "width" "100%" ] [ text slice.log ]
                            ]
                        ]
