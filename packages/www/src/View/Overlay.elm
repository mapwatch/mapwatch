module View.Overlay exposing (view)

import Time
import Html as H
import Html.Attributes as A
import Html.Events as E
import Maybe.Extra
import Model as Model exposing (Model, Msg)
import Mapwatch as Mapwatch
import Mapwatch.Run as Run
import Route
import View.Util exposing (viewGoalForm, hidePreLeagueButton)
import View.Nav
import View.Setup
import View.Home exposing (maskedText, viewHeader, viewParseError, viewProgress, viewInstance, viewDate, formatDuration, formatSideAreaType, viewSideAreaName)
import View.History
import View.Icon as Icon


view : Route.TimerParams -> Model -> H.Html Msg
view qs model =
    case model.mapwatch.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            viewSetup model <| H.div [] []

        Just p ->
            if Mapwatch.isProgressDone p then
                viewMain qs model
            else
                viewSetup model <| H.div [] []


viewSetup : Model -> H.Html Msg -> H.Html Msg
viewSetup model body =
    H.div [ A.class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.mapwatch.parseError
        , body
        ]


viewMain : Route.TimerParams -> Model -> H.Html msg
viewMain qs model =
    let
        run =
            Run.current model.now model.mapwatch.instance model.mapwatch.runState
                |> Maybe.Extra.filter (Run.isBetween { before = Nothing, after = qs.after })

        hqs0 =
            Route.historyParams0

        hqs =
            { hqs0 | after = qs.after, goal = qs.goal }

        runs =
            case qs.after of
                Nothing ->
                    Run.filterToday model.now model.mapwatch.runs

                Just _ ->
                    Run.filterBetween { before = Nothing, after = qs.after } model.mapwatch.runs

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        goal =
            Run.parseGoalDuration qs.goal

        goalDuration =
            Run.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        mappingNow =
            case run of
                Just run ->
                    viewTimer (Just (Run.durationSet run).all) (goalDuration run)

                Nothing ->
                    viewTimer Nothing Nothing
    in
        H.table [ A.class "overlay-main" ]
            ((List.indexedMap (\i -> \run -> viewRow i hqs (goalDuration run) run) (List.reverse history))
                ++ [ H.tr [] [ H.td [ A.class "timer main-timer", A.colspan 2 ] [ mappingNow ] ] ]
            )


viewRow : Int -> Route.HistoryParams -> Maybe Time.Time -> Run.Run -> H.Html msg
viewRow i hqs goalDuration run =
    H.tr
        [ A.class
            (if i % 2 == 0 then
                "even"
             else
                "odd"
            )
        ]
        [ H.td [ A.class "instance" ] [ viewInstance hqs run.first.instance ]
        , H.td [ A.class "timer" ] [ viewTimer (Just (Run.durationSet run).all) goalDuration ]
        ]


viewTimer : Maybe Time.Time -> Maybe Time.Time -> H.Html msg
viewTimer dur goal =
    H.text <| View.History.formatMaybeDuration dur
