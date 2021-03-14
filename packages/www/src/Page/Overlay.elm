module Page.Overlay exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch as Mapwatch
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Model as Model exposing (Msg, OkModel)
import Page.History
import Readline exposing (Readline)
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Time exposing (Posix)
import View.Home
import View.Icon
import View.Nav
import View.Setup
import View.Util


view : OkModel -> Html Msg
view model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            viewSetup model <| div [] []

        Mapwatch.LoadingHistory _ ->
            viewSetup model <| div [] []

        Mapwatch.Ready _ ->
            viewMain model


viewSetup : OkModel -> Html Msg -> Html Msg
viewSetup model body =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Setup.view model
        , body
        ]


viewMain : OkModel -> Html msg
viewMain model =
    let
        after =
            QueryDict.getPosix Route.keys.after model.query

        goal =
            Dict.get Route.keys.goal model.query |> RunSort.parseGoalDuration

        goalDuration =
            RunSort.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        run =
            RawMapRun.current model.now model.mapwatch.instance model.mapwatch.runState
                |> Maybe.map (MapRun.fromRaw model.mapwatch.datamine)
                |> Maybe.Extra.filter (RunSort.isBetween { before = Nothing, after = after })

        runs =
            case after of
                Nothing ->
                    RunSort.filterToday model.tz model.now model.mapwatch.runs

                Just _ ->
                    RunSort.filterBetween { before = Nothing, after = after } model.mapwatch.runs

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        viewIndexRun i run_ =
            viewRow model.query (List.length history) i (goalDuration run_) run_
    in
    div [ class "overlay-main" ]
        [ table [] <|
            List.indexedMap viewIndexRun <|
                List.reverse history
        ]


type alias Duration =
    Int


viewRow : QueryDict -> Int -> Int -> Maybe Duration -> MapRun -> Html msg
viewRow query count i goalDuration run =
    let
        isLast =
            i >= count - 1
    in
    tr
        [ classList
            [ ( "even", modBy 2 i == 0 )
            , ( "odd", modBy 2 i /= 0 )
            , ( "last", isLast )
            ]
        ]
        ([ td [ class "instance" ]
            ([ View.Home.viewAddress query { isBlightedMap = False, heistNpcs = Set.empty } run.address ]
                ++ (if isLast then
                        [ a [ class "overlay-back", Route.href query Route.Timer ] [ View.Icon.fas "cog" ] ]

                    else
                        []
                   )
            )
         , td [ class "timer" ] [ viewTimer (Just run.duration.all) ]
         ]
            ++ (case goalDuration of
                    Nothing ->
                        []

                    Just _ ->
                        [ td [ class "goal" ] [ viewGoalTimer (Just run.duration.all) goalDuration ] ]
               )
        )


viewTimer : Maybe Duration -> Html msg
viewTimer dur =
    text <| Page.History.formatMaybeDuration dur


viewGoalTimer : Maybe Duration -> Maybe Duration -> Html msg
viewGoalTimer dur goal =
    Page.History.viewDurationDelta dur goal
