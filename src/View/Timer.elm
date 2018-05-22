module View.Timer exposing (view)

import Time
import Html as H
import Html.Attributes as A
import Html.Events as E
import Model as Model exposing (Model, Msg)
import Model.Run as Run
import Model.Route as Route
import View.Nav
import View.Setup
import View.Home exposing (maskedText, viewHeader, viewParseError, viewProgress, viewInstance, viewDate, formatDuration, formatSideAreaType, viewSideAreaName)
import View.History
import View.Icon as Icon


view : Model -> H.Html Msg
view model =
    H.div []
        [ viewHeader
        , View.Nav.view model.route
        , View.Setup.view model
        , viewParseError model.parseError
        , viewBody model
        ]


viewBody : Model -> H.Html msg
viewBody model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Model.isProgressDone p then
                    -- all done!
                    [ viewMain model ]
                 else
                    [ viewProgress p ]
                )


viewMain : Model -> H.Html msg
viewMain model =
    let
        today =
            Run.filterToday model.now model.runs

        run =
            Run.current model.now model.instance model.runState

        history =
            List.take 5 <|
                (Maybe.withDefault [] <| Maybe.map List.singleton run)
                    -- ++ model.runs
                    ++ today

        historyTable =
            H.table [ A.class "timer history" ]
                [ H.tbody [] (List.concat <| List.map (View.History.viewHistoryRun { showDate = False }) <| history)
                , H.tfoot [] [ H.tr [] [ H.td [ A.colspan 11 ] [ H.a [ Route.href Route.HistoryRoot ] [ Icon.fas "history", H.text " History" ] ] ] ]
                ]
    in
        case run of
            Nothing ->
                H.div []
                    [ viewTimer Nothing
                    , H.table [ A.class "timer-details" ]
                        [ H.tbody []
                            [ H.tr [] [ H.td [] [ H.text "Not mapping" ], H.td [] [] ]
                            , H.tr [] [ H.td [] [ H.text "Last entered: " ], H.td [] [ viewInstance model.instance.val ] ]
                            , H.tr [] [ H.td [] [ H.text "Maps done today: " ], H.td [] [ H.text <| toString <| List.length today ] ]
                            ]
                        ]
                    , historyTable
                    ]

            Just run ->
                let
                    d =
                        Run.durationSet run
                in
                    H.div []
                        [ viewTimer <| Just d.all
                        , H.table [ A.class "timer-details" ]
                            [ H.tr [] [ H.td [] [ H.text "Mapping in: " ], H.td [] [ viewInstance run.first.instance ] ]
                            , H.tr [] [ H.td [] [ H.text "Last entered: " ], H.td [] [ viewInstance model.instance.val ] ]
                            , H.tr [] [ H.td [] [ H.text "Maps done today: " ], H.td [] [ H.text <| toString <| List.length today ] ]
                            ]
                        , historyTable
                        ]


viewTimer : Maybe Time.Time -> H.Html msg
viewTimer d =
    let
        durStr =
            case d of
                Just d ->
                    formatDuration d

                Nothing ->
                    "--:--"
    in
        H.div [ A.class "main-timer" ] <|
            [ H.div [] [ H.text durStr ] ]
