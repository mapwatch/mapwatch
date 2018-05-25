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


view : Route.TimerParams -> Model -> H.Html Msg
view qs model =
    H.div []
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.parseError
        , viewBody qs model
        ]


viewBody : Route.TimerParams -> Model -> H.Html msg
viewBody qs model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Model.isProgressDone p then
                    -- all done!
                    [ viewMain qs model ]
                 else
                    [ viewProgress p ]
                )


viewMain : Route.TimerParams -> Model -> H.Html msg
viewMain qs model =
    let
        run =
            Run.current model.now model.instance model.runState

        hideEarlierButton =
            H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Just model.now } ] [ Icon.fas "eye-slash", H.text " Hide earlier maps" ]

        hqs =
            { search = Nothing, page = 0, sort = Nothing, after = Nothing, before = Nothing }

        ( sessname, runs, sessionButtons ) =
            case qs.after of
                Nothing ->
                    ( "today"
                    , (Maybe.withDefault [] <| Maybe.map List.singleton run) ++ (Run.filterToday model.now model.runs)
                    , [ hideEarlierButton
                      ]
                    )

                Just _ ->
                    ( "this session"
                    , Run.filterBetween { before = Nothing, after = qs.after }
                        ((Maybe.withDefault [] <| Maybe.map List.singleton run) ++ model.runs)
                    , [ H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Nothing } ] [ Icon.fas "eye", H.text " Unhide all" ]
                      , hideEarlierButton
                      , H.a [ A.class "button", Route.href <| Route.History { hqs | after = qs.after, before = Just model.now } ] [ Icon.fas "camera", H.text " Snapshot history" ]
                      ]
                    )

        history =
            List.take 5 runs

        historyTable =
            H.table [ A.class "timer history" ]
                [ H.tbody [] (List.concat <| List.map (View.History.viewHistoryRun { showDate = False } hqs) <| history)
                , H.tfoot [] [ H.tr [] [ H.td [ A.colspan 11 ] [ H.a [ Route.href <| Route.History { hqs | after = qs.after } ] [ Icon.fas "history", H.text " History" ] ] ] ]
                ]

        ( timer, mappingNow ) =
            case run of
                Just run ->
                    ( Just (Run.durationSet run).all
                    , [ H.td [] [ H.text "Mapping in: " ], H.td [] [ viewInstance hqs run.first.instance ] ]
                    )

                Nothing ->
                    ( Nothing
                    , [ H.td [] [ H.text "Not mapping" ]
                      , H.td [] []
                      ]
                    )
    in
        H.div []
            [ viewTimer timer
            , H.table [ A.class "timer-details" ]
                [ H.tbody []
                    [ H.tr [] mappingNow
                    , H.tr [] [ H.td [] [ H.text "Last entered: " ], H.td [] [ viewInstance hqs model.instance.val ] ]
                    , H.tr [] [ H.td [] [ H.text <| "Maps done " ++ sessname ++ ": " ], H.td [] [ H.text <| toString <| List.length runs ] ]
                    , H.tr [ A.class "session-buttons" ]
                        (if qs.enableSession then
                            [ H.td [ A.colspan 2 ] sessionButtons ]
                         else
                            []
                        )
                    ]
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
