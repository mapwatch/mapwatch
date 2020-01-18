module View.Overlay exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch as Mapwatch
import Mapwatch.Run as Run
import Maybe.Extra
import Model as Model exposing (Msg, OkModel)
import Readline exposing (Readline)
import Route
import Time
import View.History
import View.Home exposing (formatDuration, maskedText, viewAddress, viewDate, viewHeader, viewProgress, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util exposing (hidePreLeagueButton, viewGoalForm)


view : Route.TimerParams -> OkModel -> Html Msg
view qs model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            viewSetup model <| div [] []

        Mapwatch.LoadingHistory _ ->
            viewSetup model <| div [] []

        Mapwatch.Ready _ ->
            viewMain qs model


viewSetup : OkModel -> Html Msg -> Html Msg
viewSetup model body =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , body
        ]


viewMain : Route.TimerParams -> OkModel -> Html msg
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
                    Run.filterToday model.tz model.now model.mapwatch.runs

                Just _ ->
                    Run.filterBetween { before = Nothing, after = qs.after } model.mapwatch.runs

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        goal =
            Run.parseGoalDuration qs.goal

        goalDuration =
            Run.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        viewIndexRun i run_ =
            viewRow (List.length history) i qs hqs (goalDuration run_) run_
    in
    div [ class "overlay-main" ]
        [ table [] <|
            List.indexedMap viewIndexRun <|
                List.reverse history
        ]


type alias Duration =
    Int


viewRow : Int -> Int -> Route.TimerParams -> Route.HistoryParams -> Maybe Duration -> Run.Run -> Html msg
viewRow count i tqs hqs goalDuration run =
    let
        isLast =
            i >= count - 1

        dur =
            Just (Run.durationSet run).all
    in
    tr
        [ classList
            [ ( "even", modBy 2 i == 0 )
            , ( "odd", modBy 2 i /= 0 )
            , ( "last", isLast )
            ]
        ]
        ([ td [ class "instance" ]
            ([ viewAddress hqs { blighted = False } run.address ]
                ++ (if isLast then
                        [ a [ class "overlay-back", Route.href <| Route.Timer tqs ] [ Icon.fas "cog" ] ]

                    else
                        []
                   )
            )
         , td [ class "timer" ] [ viewTimer dur ]
         ]
            ++ (case goalDuration of
                    Nothing ->
                        []

                    Just _ ->
                        [ td [ class "goal" ] [ viewGoalTimer dur goalDuration ] ]
               )
        )


viewTimer : Maybe Duration -> Html msg
viewTimer dur =
    text <| View.History.formatMaybeDuration dur


viewGoalTimer : Maybe Duration -> Maybe Duration -> Html msg
viewGoalTimer dur goal =
    View.History.viewDurationDelta dur goal
