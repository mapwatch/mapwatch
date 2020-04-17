module View.Timer exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch as Mapwatch
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.MapRun.Sort as RunSort
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Model as Model exposing (Msg, OkModel)
import Route
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Time exposing (Posix)
import View.History
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
                [ View.Icon.fas "eye-slash", text " Hide earlier maps" ]

        ( sessname, runs, sessionButtons ) =
            case after of
                Nothing ->
                    ( "today"
                    , RunSort.filterToday model.tz model.now model.mapwatch.runs
                    , [ hideEarlierButton
                      , View.Util.hidePreLeagueButton model.query model.route
                      ]
                    )

                Just _ ->
                    ( "this session"
                    , RunSort.filterBetween { before = Nothing, after = after } model.mapwatch.runs
                    , [ a [ class "button", Route.href (Dict.remove Route.keys.after model.query) Route.Timer ]
                            [ View.Icon.fas "eye", text " Unhide all" ]
                      , hideEarlierButton
                      , a [ class "button", Route.href (QueryDict.insertPosix Route.keys.before model.now model.query) Route.History ]
                            [ View.Icon.fas "camera", text " Snapshot history" ]
                      ]
                    )

        history =
            List.take 5 <| Maybe.Extra.toList run ++ runs

        historyTable =
            table [ class "timer history" ]
                [ tbody [] (List.concat <| List.map (View.History.viewHistoryRun model { showDate = False } goalDuration) <| history)
                , tfoot []
                    [ tr []
                        [ td [ colspan 12 ]
                            (if Feature.isActive Feature.ConquerorStatus model.query then
                                [ viewConquerorsState model.query (Conqueror.createState (Maybe.Extra.toList run ++ model.mapwatch.runs)) ]

                             else
                                []
                            )
                        ]
                    , tr []
                        [ td [ colspan 12, class "timer-links" ]
                            [ a [ Route.href model.query Route.History ] [ View.Icon.fas "history", text " History" ]
                            , a [ Route.href model.query Route.Overlay ] [ View.Icon.fas "align-justify", text " Overlay" ]
                            ]
                        ]
                    ]
                ]

        ( timer, timerGoal, mappingNow ) =
            case run of
                Just run_ ->
                    ( Just run_.duration.all
                    , goalDuration run_
                    , [ td [] [ text "Mapping in: " ], td [] [ View.Home.viewRun model.query run_ ] ]
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
                        [ View.Home.viewMaybeInstance model.query <| Maybe.map .val model.mapwatch.instance
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


viewConquerorsState : QueryDict -> Conqueror.State -> Html msg
viewConquerorsState query state =
    ul [ class "conquerors-state" ]
        [ viewConquerorsStateEntry query state.baran Conqueror.Baran
        , viewConquerorsStateEntry query state.veritania Conqueror.Veritania
        , viewConquerorsStateEntry query state.alHezmin Conqueror.AlHezmin
        , viewConquerorsStateEntry query state.drox Conqueror.Drox
        ]


viewConquerorsStateEntry : QueryDict -> Conqueror.State1 -> Conqueror.Id -> Html msg
viewConquerorsStateEntry query state id =
    let
        href =
            Route.href (Dict.insert Route.keys.search "eye of the storm|baran|veritania|al-hezmin|drox" query) Route.History

        ( icon, name ) =
            case id of
                Conqueror.Baran ->
                    ( View.Icon.baran, "Baran" )

                Conqueror.Veritania ->
                    ( View.Icon.veritania, "Veritania" )

                Conqueror.AlHezmin ->
                    ( View.Icon.alHezmin, "Al-Hezmin" )

                Conqueror.Drox ->
                    ( View.Icon.drox, "Drox" )

        sightings : String
        sightings =
            (case state.region of
                Nothing ->
                    "\n\n"

                Just r ->
                    " in "
                        ++ r
                        ++ "\n\n"
            )
                ++ (if state.sightings == Set.empty then
                        "Past sightings: none"

                    else
                        "Past sightings: " ++ (state.sightings |> Set.toList |> String.join ", ")
                   )
    in
    case state.encounter of
        Nothing ->
            li [ title <| name ++ ": Unmet" ++ sightings ]
                [ a [ href ]
                    [ View.Icon.conquerorRegions id state, icon, text "0×", text name ]
                ]

        Just (Conqueror.Taunt n) ->
            li [ title <| name ++ ": " ++ String.fromInt n ++ View.Util.pluralize " taunt" " taunts" n ++ sightings ]
                [ a [ href ]
                    [ View.Icon.conquerorRegions id state, icon, text (String.fromInt n ++ "×"), text name ]
                ]

        Just Conqueror.Fight ->
            -- ☑
            li [ title <| name ++ ": Fought" ++ sightings ]
                [ a [ href ]
                    [ View.Icon.conquerorRegions id state, icon, text "✔ ", text name ]
                ]
