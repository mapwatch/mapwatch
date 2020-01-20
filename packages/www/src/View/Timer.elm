module View.Timer exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch as Mapwatch
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.MapRun.Sort as RunSort
import Maybe.Extra
import Model as Model exposing (Msg, OkModel)
import Route
import Time
import View.History
import View.Home exposing (formatDuration, maskedText, viewDate, viewHeader, viewMaybeInstance, viewProgress, viewRun, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util exposing (hidePreLeagueButton, viewGoalForm)
import View.Volume


view : Route.TimerParams -> OkModel -> Html Msg
view qs model =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewBody qs model
        ]


viewBody : Route.TimerParams -> OkModel -> Html Msg
viewBody qs model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            viewProgress p

        Mapwatch.Ready _ ->
            div []
                [ View.Volume.view model
                , viewGoalForm (\goal -> Model.RouteTo <| Route.Timer { qs | goal = goal }) qs
                , viewMain qs model
                ]


viewMain : Route.TimerParams -> OkModel -> Html Msg
viewMain qs model =
    let
        run : Maybe MapRun
        run =
            RawMapRun.current model.now model.mapwatch.instance model.mapwatch.runState
                |> Maybe.map MapRun.fromRaw
                |> Maybe.Extra.filter (RunSort.isBetween { before = Nothing, after = qs.after })

        hideEarlierButton =
            a [ class "button", Route.href <| Route.Timer { qs | after = Just model.now } ] [ Icon.fas "eye-slash", text " Hide earlier maps" ]

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
                    , RunSort.filterToday model.tz model.now model.mapwatch.runs
                    , [ hideEarlierButton
                      , hidePreLeagueButton (\after -> Route.Timer { qs | after = Just after })
                      ]
                    )

                Just _ ->
                    ( "this session"
                    , RunSort.filterBetween { before = Nothing, after = qs.after } model.mapwatch.runs
                    , [ a [ class "button", Route.href <| Route.Timer { qs | after = Nothing } ] [ Icon.fas "eye", text " Unhide all" ]
                      , hideEarlierButton
                      , a [ class "button", Route.href <| Route.History { hqs | before = Just model.now } ] [ Icon.fas "camera", text " Snapshot history" ]
                      ]
                    )

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        goal =
            RunSort.parseGoalDuration qs.goal

        goalDuration =
            RunSort.goalDuration goal { session = runs, allTime = model.mapwatch.runs }

        historyTable =
            table [ class "timer history" ]
                [ tbody [] (List.concat <| List.map (View.History.viewHistoryRun model.tz { showDate = False } hqs goalDuration) <| history)
                , tfoot []
                    [ tr [] [ td [ colspan 12 ] [ viewConquerorsState (Conqueror.createState (Maybe.Extra.toList run ++ model.mapwatch.runs)) ] ]
                    , tr []
                        [ td [ colspan 12 ]
                            [ a [ Route.href <| Route.History hqs ] [ Icon.fas "history", text " History" ]
                            , a [ Route.href <| Route.Overlay oqs ] [ Icon.fas "align-justify", text " Overlay" ]
                            ]
                        ]
                    ]
                ]

        ( timer, timerGoal, mappingNow ) =
            case run of
                Just run_ ->
                    ( Just run_.duration.all
                    , goalDuration run_
                    , [ td [] [ text "Mapping in: " ], td [] [ viewRun hqs run_ ] ]
                    )

                Nothing ->
                    ( Nothing
                    , Nothing
                    , [ td [] [ text "Not mapping" ]
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
                    [ td [] [ text "Last entered: " ]
                    , td []
                        [ viewMaybeInstance hqs <| Maybe.map .val model.mapwatch.instance
                        , small [ style "opacity" "0.5" ]
                            [ text " ("
                            , text <| View.History.formatMaybeDuration sinceLastUpdated
                            , text ")"
                            ]
                        ]
                    ]
                , tr [] [ td [] [ text <| "Maps done " ++ sessname ++ ": " ], td [] [ text <| String.fromInt <| List.length runs ] ]
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
            [ div [] [ text <| View.History.formatMaybeDuration dur ] ]
        , div [ class "sub-timer" ]
            [ div [] [ View.History.viewDurationDelta dur goal ] ]
        ]


viewConquerorsState : Conqueror.State -> Html msg
viewConquerorsState state =
    ul [ class "conquerors-state" ]
        [ viewConquerorsStateEntry state.baran Icon.baran "Baran"
        , viewConquerorsStateEntry state.veritania Icon.veritania "Veritania"
        , viewConquerorsStateEntry state.alHezmin Icon.alHezmin "Al-Hezmin"
        , viewConquerorsStateEntry state.drox Icon.drox "Drox"
        ]


viewConquerorsStateEntry : Maybe Conqueror.Encounter -> Html msg -> String -> Html msg
viewConquerorsStateEntry encounter icon name =
    case encounter of
        Nothing ->
            li [ title <| name ++ ": Unmet" ] [ text "0×", icon, text name ]

        Just (Conqueror.Taunt n) ->
            li [ title <| name ++ ": " ++ String.fromInt n ++ " Taunts" ] [ text (String.fromInt n ++ "×"), icon, text name ]

        Just Conqueror.Fight ->
            -- li [ title "Fought" ] (text "☑" :: label)
            li [ title <| name ++ ": Fought" ] [ text "✔", icon, text name ]
