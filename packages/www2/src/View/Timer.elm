module View.Timer exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Mapwatch as Mapwatch
import Mapwatch.Run as Run exposing (Run)
import Maybe.Extra
import Model as Model exposing (Model, Msg)
import Route
import Time
import View.History
import View.Home exposing (formatDuration, formatSideAreaType, maskedText, viewDate, viewHeader, viewInstance, viewParseError, viewProgress, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util exposing (hidePreLeagueButton, viewGoalForm)
import View.Volume


view : Route.TimerParams -> Model -> H.Html Msg
view qs model =
    H.div [ A.class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.mapwatch.parseError
        , viewBody qs model
        ]


viewBody : Route.TimerParams -> Model -> H.Html Msg
viewBody qs model =
    case model.mapwatch.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                if Mapwatch.isProgressDone p then
                    -- all done!
                    [ View.Volume.view model
                    , viewGoalForm (\goal -> Model.RouteTo <| Route.Timer { qs | goal = goal }) qs
                    , viewMain qs model
                    ]

                else
                    [ viewProgress p ]


viewMain : Route.TimerParams -> Model -> H.Html Msg
viewMain qs model =
    let
        run : Maybe Run
        run =
            Run.current model.now model.mapwatch.instance model.mapwatch.runState
                |> Maybe.Extra.filter (Run.isBetween { before = Nothing, after = qs.after })

        hideEarlierButton =
            H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Just model.now } ] [ Icon.fas "eye-slash", H.text " Hide earlier maps" ]

        hqs0 =
            Route.historyParams0

        hqs =
            { hqs0 | after = qs.after, goal = qs.goal }

        oqs0 =
            Route.overlayParams0

        oqs =
            { oqs0 | after = qs.after, goal = qs.goal }

        ( sessname, runs, sessionButtons ) =
            case qs.after of
                Nothing ->
                    ( "today"
                    , Run.filterToday model.tz model.now model.mapwatch.runs
                    , [ hideEarlierButton
                      , hidePreLeagueButton (\after -> Route.Timer { qs | after = Just after })
                      ]
                    )

                Just _ ->
                    ( "this session"
                    , Run.filterBetween { before = Nothing, after = qs.after } model.mapwatch.runs
                    , [ H.a [ A.class "button", Route.href <| Route.Timer { qs | after = Nothing } ] [ Icon.fas "eye", H.text " Unhide all" ]
                      , hideEarlierButton
                      , H.a [ A.class "button", Route.href <| Route.History { hqs | before = Just model.now } ] [ Icon.fas "camera", H.text " Snapshot history" ]
                      ]
                    )

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        goal =
            Run.parseGoalDuration qs.goal

        goalDuration =
            Run.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        historyTable =
            H.table [ A.class "timer history" ]
                [ H.tbody [] (List.concat <| List.map (View.History.viewHistoryRun { showDate = False } hqs goalDuration) <| history)
                , H.tfoot []
                    [ H.tr []
                        [ H.td [ A.colspan 11 ]
                            [ H.a [ Route.href <| Route.History hqs ] [ Icon.fas "history", H.text " History" ]
                            , H.a [ Route.href <| Route.Overlay oqs ] [ Icon.fas "align-justify", H.text " Overlay" ]
                            ]
                        ]
                    ]
                ]

        ( timer, timerGoal, mappingNow ) =
            case run of
                Just run_ ->
                    ( Just (Run.durationSet run_).all
                    , goalDuration run_
                    , [ H.td [] [ H.text "Mapping in: " ], H.td [] [ viewInstance hqs run_.first.instance ] ]
                    )

                Nothing ->
                    ( Nothing
                    , Nothing
                    , [ H.td [] [ H.text "Not mapping" ]
                      , H.td [] []
                      ]
                    )

        sinceLastUpdated : Maybe Duration
        sinceLastUpdated =
            model.mapwatch
                |> Mapwatch.lastUpdatedAt
                |> Maybe.map (\t -> Time.posixToMillis model.now - Time.posixToMillis t)
    in
    H.div []
        [ viewTimer timer timerGoal
        , H.table [ A.class "timer-details" ]
            [ H.tbody []
                [ H.tr [] mappingNow
                , H.tr []
                    [ H.td [] [ H.text "Last entered: " ]
                    , H.td []
                        [ viewInstance hqs model.mapwatch.instance.val
                        , H.small [ A.style "opacity" "0.5" ]
                            [ H.text " ("
                            , H.text <| View.History.formatMaybeDuration sinceLastUpdated
                            , H.text ")"
                            ]
                        ]
                    ]
                , H.tr [] [ H.td [] [ H.text <| "Maps done " ++ sessname ++ ": " ], H.td [] [ H.text <| String.fromInt <| List.length runs ] ]
                , H.tr [ A.class "session-buttons" ] [ H.td [ A.colspan 2 ] sessionButtons ]
                ]
            ]
        , historyTable
        ]


type alias Duration =
    Int


viewTimer : Maybe Duration -> Maybe Duration -> H.Html msg
viewTimer dur goal =
    H.div []
        [ H.div [ A.class "main-timer" ]
            [ H.div [] [ H.text <| View.History.formatMaybeDuration dur ] ]
        , H.div [ A.class "sub-timer" ]
            [ H.div [] [ View.History.viewDurationDelta dur goal ] ]
        ]