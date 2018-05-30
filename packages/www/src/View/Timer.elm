module View.Timer exposing (view)

import Time
import Html as H
import Html.Attributes as A
import Html.Events as E
import Maybe.Extra
import Mapwatch as Mapwatch exposing (Model, Msg)
import Mapwatch.Run as Run
import Mapwatch.Route as Route
import View.Util exposing (viewGoalForm)
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


viewBody : Route.TimerParams -> Model -> H.Html Msg
viewBody qs model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Mapwatch.isProgressDone p then
                    -- all done!
                    [ viewGoalForm (\goal -> Mapwatch.RouteTo <| Route.Timer { qs | goal = goal }) qs
                    , viewMain qs model
                    ]
                 else
                    [ viewProgress p ]
                )


viewMain : Route.TimerParams -> Model -> H.Html msg
viewMain qs model =
    let
        run =
            Run.current model.now model.instance model.runState
                |> Maybe.Extra.filter (Run.isBetween { before = Nothing, after = qs.after })

        hideEarlierButton =
            H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Just model.now } ] [ Icon.fas "eye-slash", H.text " Hide earlier maps" ]

        hqs =
            Route.historyParams0

        ( sessname, runs, sessionButtons ) =
            case qs.after of
                Nothing ->
                    ( "today"
                    , Run.filterToday model.now model.runs
                    , [ hideEarlierButton
                      ]
                    )

                Just _ ->
                    ( "this session"
                    , Run.filterBetween { before = Nothing, after = qs.after } model.runs
                    , [ H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Nothing } ] [ Icon.fas "eye", H.text " Unhide all" ]
                      , hideEarlierButton
                      , H.a [ A.class "button", Route.href <| Route.History { hqs | after = qs.after, before = Just model.now, goal = qs.goal } ] [ Icon.fas "camera", H.text " Snapshot history" ]
                      ]
                    )

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        goal =
            Run.parseGoalDuration qs.goal

        goalDuration =
            Run.goalDuration goal { session = runs, allTime = model.runs }

        historyTable =
            H.table [ A.class "timer history" ]
                [ H.tbody [] (List.concat <| List.map (View.History.viewHistoryRun { showDate = False } hqs goalDuration) <| history)
                , H.tfoot [] [ H.tr [] [ H.td [ A.colspan 11 ] [ H.a [ Route.href <| Route.History { hqs | after = qs.after } ] [ Icon.fas "history", H.text " History" ] ] ] ]
                ]

        ( timer, timerGoal, mappingNow ) =
            case run of
                Just run ->
                    ( Just (Run.durationSet run).all
                    , goalDuration run
                    , [ H.td [] [ H.text "Mapping in: " ], H.td [] [ viewInstance hqs run.first.instance ] ]
                    )

                Nothing ->
                    ( Nothing
                    , Nothing
                    , [ H.td [] [ H.text "Not mapping" ]
                      , H.td [] []
                      ]
                    )
    in
        H.div []
            [ viewTimer timer timerGoal
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


viewTimer : Maybe Time.Time -> Maybe Time.Time -> H.Html msg
viewTimer dur goal =
    H.div []
        [ H.div [ A.class "main-timer" ]
            [ H.div [] [ H.text <| View.History.formatMaybeDuration dur ] ]
        , H.div [ A.class "sub-timer" ]
            [ H.div [] [ View.History.viewDurationDelta dur goal ] ]
        ]
