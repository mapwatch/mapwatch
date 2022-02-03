module Page.Timer exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.MapRun.Sort as RunSort
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Model exposing (Msg, OkModel)
import Page.History
import Route
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Time exposing (Posix)
import View.Drops
import View.Home
import View.Icon
import View.Nav
import View.Setup
import View.Util


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

        Mapwatch.Ready _ ->
            div []
                [ View.Util.viewGoalForm model.query
                , View.Setup.viewDownloadLink model
                , viewMain model
                ]


viewMain : OkModel -> Html Msg
viewMain model =
    let
        before =
            QueryDict.getPosix Route.keys.before model.query

        after =
            QueryDict.getPosix Route.keys.after model.query

        goal =
            Dict.get Route.keys.goal model.query |> RunSort.parseGoalDuration

        goalDuration =
            RunSort.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        run : Maybe MapRun
        run =
            RawMapRun.current model.now model.mapwatch.instance model.mapwatch.runState
                |> Maybe.map (MapRun.fromRaw model.mapwatch.datamine)
                |> Maybe.Extra.filter (RunSort.isBetween { before = Nothing, after = after })

        hideEarlierButton =
            a [ class "button", Route.href (QueryDict.insertPosix Route.keys.after model.now model.query) Route.Timer ]
                [ View.Icon.fas "eye-slash", text " ", span [ L.timerHideEarlier ] [] ]

        ( sessname, runs, sessionButtons ) =
            case after of
                Nothing ->
                    ( L.timerDoneToday
                    , RunSort.filterToday model.tz model.now model.mapwatch.runs
                    , hideEarlierButton
                        :: View.Util.hidePreLeagueButtons model.mapwatch.datamine.leagues model.query model.route
                    )

                Just _ ->
                    ( L.timerDoneThisSession
                    , RunSort.filterBetween { before = Nothing, after = after } model.mapwatch.runs
                    , [ a [ class "button", Route.href (Dict.remove Route.keys.after model.query) Route.Timer ]
                            [ View.Icon.fas "eye", text " ", span [ L.timerUnhide ] [] ]
                      , hideEarlierButton
                      , a [ class "button", Route.href (QueryDict.insertPosix Route.keys.before model.now model.query) Route.History ]
                            [ View.Icon.fas "camera", text " ", span [ L.timerSnapshot ] [] ]
                      ]
                    )

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        historyTable =
            table [ class "timer history" ]
                [ tbody [] (List.concat <| List.map (Page.History.viewHistoryRun model { showDate = False, loadedAt = model.loadedAt } goalDuration) <| history)
                , tfoot []
                    [ tr []
                        [ td [ colspan 12, class "timer-links" ]
                            [ a [ Route.href model.query Route.History ] [ View.Icon.fas "history", text " ", span [ L.timerHistory ] [] ]
                            , a [ Route.href model.query Route.Overlay ] [ View.Icon.fas "align-justify", text " ", span [ L.timerOverlay ] [] ]
                            ]
                        ]
                    ]
                ]

        ( timer, timerGoal, mappingNow ) =
            case run of
                Just run_ ->
                    ( Just run_.duration.all
                    , goalDuration run_
                    , [ td [ style "vertical-align" "top", L.timerIn ] []
                      , td [] <|
                            case run_.address.worldArea of
                                Nothing ->
                                    [ View.Home.viewRun model.query run_
                                    , span [] []
                                    , View.Drops.empty
                                    ]

                                Just w ->
                                    [ View.Home.viewRun model.query run_
                                    , span []
                                        [ text " ("
                                        , a [ target "_blank", href <| Datamine.wikiUrl model.mapwatch.datamine w, L.timerMapWiki ] []
                                        , text ")"
                                        ]
                                    , View.Drops.view model.query model.mapwatch.datamine w
                                    ]
                      ]
                    )

                Nothing ->
                    ( Nothing
                    , Nothing
                    , [ td [ L.timerNotMapping ] []
                      , td [] []
                      ]
                    )

        sinceLastUpdated : Maybe Duration
        sinceLastUpdated =
            model.mapwatch
                |> Mapwatch.lastUpdatedAt
                |> Maybe.map (\t -> Time.posixToMillis model.now - Time.posixToMillis t |> Basics.max 0)
    in
    div []
        [ viewTimer timer timerGoal
        , table [ class "timer-details" ]
            [ tbody []
                [ tr [] mappingNow
                , tr []
                    [ td [ L.timerLastEntered ] []
                    , td []
                        [ View.Home.viewMaybeInstance model.query <| Maybe.map .val model.mapwatch.instance
                        , small [ style "opacity" "0.5" ]
                            [ text " ("
                            , text <| Page.History.formatMaybeDuration sinceLastUpdated
                            , text ")"
                            ]
                        ]
                    ]
                , tr [] [ td [ sessname ] [], td [] [ text <| String.fromInt <| List.length runs ] ]
                , tr [ class "session-buttons" ] [ td [ colspan 2 ] sessionButtons ]
                ]
            ]
        , historyTable
        ]


type alias Duration =
    Int


viewTimer : Maybe Duration -> Maybe Duration -> Html msg
viewTimer dur goal =
    div []
        [ div [ class "main-timer" ]
            [ div [] [ text <| Page.History.formatMaybeDuration dur ] ]
        , div [ class "sub-timer" ]
            [ div [] [ Page.History.viewDurationDelta dur goal ] ]
        ]
