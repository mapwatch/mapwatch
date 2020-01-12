module View.History exposing (formatMaybeDuration, view, viewDurationDelta, viewDurationSet, viewHistoryRun)

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch as Mapwatch
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Run as Run exposing (Run)
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Regex
import Route
import Time
import View.Home exposing (formatDuration, maskedText, viewDate, viewHeader, viewInstance, viewParseError, viewProgress, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.NotFound
import View.Setup
import View.Util exposing (pluralize, roundToPlaces, viewDateSearch, viewGoalForm, viewSearch)
import View.Volume


view : Route.HistoryParams -> OkModel -> Html Msg
view params model =
    if Mapwatch.isReady model.mapwatch && not (isValidPage params.page model) then
        View.NotFound.view

    else
        div [ class "main" ]
            [ viewHeader
            , View.Nav.view <| Just model.route
            , View.Setup.view model
            , viewParseError model.mapwatch.parseError
            , viewBody params model
            ]


viewBody : Route.HistoryParams -> OkModel -> Html Msg
viewBody params model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            viewProgress p

        Mapwatch.Ready p ->
            div []
                [ viewMain params model
                , viewProgress p
                ]


perPage =
    25


numPages : Int -> Int
numPages numItems =
    ceiling <| toFloat numItems / toFloat perPage


isValidPage : Int -> OkModel -> Bool
isValidPage page model =
    case model.mapwatch.readline of
        Nothing ->
            True

        Just _ ->
            page == clamp 0 (numPages (List.length model.mapwatch.runs) - 1) page


viewMain : Route.HistoryParams -> OkModel -> Html Msg
viewMain params model =
    let
        currentRun : Maybe Run
        currentRun =
            -- include the current run if we're viewing a snapshot
            Maybe.andThen (\b -> Run.current b model.mapwatch.instance model.mapwatch.runState) params.before

        runs =
            model.mapwatch.runs
                |> (++) (Maybe.Extra.toList currentRun)
                |> Maybe.Extra.unwrap identity Run.search params.search
                |> Run.filterBetween params
                |> Run.sort params.sort
    in
    div []
        [ div []
            [ View.Volume.view model
            , viewSearch [ placeholder "area name" ]
                (\q ->
                    { params
                        | search =
                            if q == "" then
                                Nothing

                            else
                                Just q
                    }
                        |> HistorySearch
                )
                params.search
            , viewDateSearch (\qs1 -> Route.History { params | before = qs1.before, after = qs1.after }) params
            , viewGoalForm (\goal -> Model.RouteTo <| Route.History { params | goal = goal }) params
            ]
        , viewStatsTable params model.tz model.now runs
        , viewHistoryTable params runs model
        ]


viewStatsTable : Route.HistoryParams -> Time.Zone -> Time.Posix -> List Run -> Html msg
viewStatsTable qs tz now runs =
    table [ class "history-stats" ]
        [ tbody []
            (case ( qs.after, qs.before ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (text "Today") (Run.filterToday tz now runs)
                        , viewStatsRows (text "All-time") runs
                        ]

                _ ->
                    viewStatsRows (text "This session") (Run.filterBetween qs runs)
            )
        ]


viewStatsRows : Html msg -> List Run -> List (Html msg)
viewStatsRows title runs =
    [ tr []
        [ th [ class "title" ] [ title ]
        , td [ colspan 10, class "maps-completed" ] [ text <| String.fromInt (List.length runs) ++ pluralize " map" " maps" (List.length runs) ++ " completed" ]
        ]
    , tr []
        ([ td [] []
         , td [] [ text "Average time per map" ]
         ]
            ++ viewDurationSet (Run.meanDurationSet runs)
        )
    , tr []
        ([ td [] []
         , td [] [ text "Total time" ]
         ]
            ++ viewDurationSet (Run.totalDurationSet runs)
        )
    ]


viewPaginator : Route.HistoryParams -> Int -> Html msg
viewPaginator ({ page } as ps) numItems =
    let
        firstVisItem =
            clamp 1 numItems <| (page * perPage) + 1

        lastVisItem =
            clamp 1 numItems <| (page + 1) * perPage

        prev =
            page - 1

        next =
            page + 1

        last =
            numPages numItems - 1

        href i =
            Route.href <| Route.History { ps | page = i }

        ( firstLink, prevLink ) =
            if page /= 0 then
                ( a [ href 0 ], a [ href prev ] )

            else
                ( span [], span [] )

        ( nextLink, lastLink ) =
            if page /= last then
                ( a [ href next ], a [ href last ] )

            else
                ( span [], span [] )
    in
    div [ class "paginator" ]
        [ firstLink [ Icon.fas "fast-backward", text " First" ]
        , prevLink [ Icon.fas "step-backward", text " Prev" ]
        , span [] [ text <| String.fromInt firstVisItem ++ " - " ++ String.fromInt lastVisItem ++ " of " ++ String.fromInt numItems ]
        , nextLink [ text "Next ", Icon.fas "step-forward" ]
        , lastLink [ text "Last ", Icon.fas "fast-forward" ]
        ]


viewHistoryTable : Route.HistoryParams -> List Run -> OkModel -> Html msg
viewHistoryTable ({ page } as params) queryRuns model =
    let
        paginator =
            viewPaginator params (List.length queryRuns)

        pageRuns =
            queryRuns
                |> List.drop (page * perPage)
                |> List.take perPage

        goalDuration =
            Run.goalDuration (Run.parseGoalDuration params.goal)
                { session =
                    case params.after of
                        Just _ ->
                            queryRuns

                        Nothing ->
                            Run.filterToday model.tz model.now model.mapwatch.runs
                , allTime = model.mapwatch.runs
                }
    in
    table [ class "history" ]
        [ thead []
            [ tr [] [ td [ colspan 11 ] [ paginator ] ]

            -- , viewHistoryHeader (Run.parseSort params.sort) params
            ]
        , tbody [] (pageRuns |> List.map (viewHistoryRun { showDate = True } params goalDuration) |> List.concat)
        , tfoot [] [ tr [] [ td [ colspan 11 ] [ paginator ] ] ]
        ]


viewSortLink : Run.SortField -> ( Run.SortField, Run.SortDir ) -> Route.HistoryParams -> Html msg
viewSortLink thisField ( sortedField, dir ) qs =
    let
        ( icon, slug ) =
            if thisField == sortedField then
                -- already sorted on this field, link changes direction
                ( Icon.fas
                    (if dir == Run.Asc then
                        "sort-up"

                     else
                        "sort-down"
                    )
                , Run.stringifySort thisField <| Just <| Run.reverseSort dir
                )

            else
                -- link sorts by this field with default direction
                ( Icon.fas "sort", Run.stringifySort thisField Nothing )
    in
    a [ Route.href <| Route.History { qs | sort = Just slug } ] [ icon ]


viewHistoryHeader : ( Run.SortField, Run.SortDir ) -> Route.HistoryParams -> Html msg
viewHistoryHeader sort qs =
    let
        link field =
            viewSortLink field sort qs
    in
    tr []
        [ th [] [ link Run.SortDate ]
        , th [ class "zone" ] [ link Run.Name ]
        , th [] [ link Run.TimeTotal ]
        , th [] []
        , th [] [ link Run.TimeMap ]
        , th [] []
        , th [] [ link Run.TimeTown ]
        , th [] []
        , th [] [ link Run.TimeSide ]
        , th [] [ link Run.Portals ]
        , th [] []
        ]


viewDuration =
    text << formatDuration


type alias HistoryRowConfig =
    { showDate : Bool }


type alias Duration =
    Int


viewHistoryRun : HistoryRowConfig -> Route.HistoryParams -> (Run -> Maybe Duration) -> Run -> List (Html msg)
viewHistoryRun config qs goals r =
    viewHistoryMainRow config qs (goals r) r :: List.map ((\f ( a, b ) -> f a b) <| viewHistorySideAreaRow config qs) (Run.durationPerSideArea r)


viewDurationSet : Run.DurationSet -> List (Html msg)
viewDurationSet d =
    [ td [ class "dur total-dur" ] [ viewDuration d.all ] ] ++ viewDurationTail d


viewGoalDurationSet : Maybe Duration -> Run.DurationSet -> List (Html msg)
viewGoalDurationSet goal d =
    [ td [ class "dur total-dur" ] [ viewDuration d.all ]
    , td [ class "dur delta-dur" ] [ viewDurationDelta (Just d.all) goal ]
    ]
        ++ viewDurationTail d


viewDurationTail : Run.DurationSet -> List (Html msg)
viewDurationTail d =
    [ td [ class "dur" ] [ text " = " ]
    , td [ class "dur" ] [ viewDuration d.mainMap, text " in map " ]
    , td [ class "dur" ] [ text " + " ]
    , td [ class "dur" ] [ viewDuration d.town, text " in town " ]
    ]
        ++ (if d.sides > 0 then
                [ td [ class "dur" ] [ text " + " ]
                , td [ class "dur" ] [ viewDuration d.sides, text " in sides" ]
                ]

            else
                [ td [ class "dur" ] [], td [ class "dur" ] [] ]
           )
        ++ [ td [ class "portals" ] [ text <| String.fromFloat (roundToPlaces 2 d.portals) ++ pluralize " portal" " portals" d.portals ]
           , td [ class "town-pct" ]
                [ text <| String.fromInt (clamp 0 100 <| floor <| 100 * (toFloat d.town / Basics.max 1 (toFloat d.all))) ++ "% in town" ]
           ]


viewHistoryMainRow : HistoryRowConfig -> Route.HistoryParams -> Maybe Duration -> Run -> Html msg
viewHistoryMainRow { showDate } qs goal r =
    let
        d =
            Run.durationSet r
    in
    tr [ class "main-area" ]
        ((if showDate then
            [ td [ class "date" ] [ viewDate r.last.leftAt ] ]

          else
            []
         )
            ++ [ td [ class "zone" ] [ viewInstance qs r.first.instance ]
               ]
            ++ viewGoalDurationSet goal d
        )


viewHistorySideAreaRow : HistoryRowConfig -> Route.HistoryParams -> Instance.Address -> Duration -> Html msg
viewHistorySideAreaRow { showDate } qs instance d =
    tr [ class "side-area" ]
        ((if showDate then
            [ td [ class "date" ] [] ]

          else
            []
         )
            ++ [ td [] []
               , td [ class "zone", colspan 7 ] [ viewSideAreaName qs (Instance.Instance instance) ]
               , td [ class "side-dur" ] [ viewDuration d ]
               , td [ class "portals" ] []
               , td [ class "town-pct" ] []
               ]
        )


viewDurationDelta : Maybe Duration -> Maybe Duration -> Html msg
viewDurationDelta mcur mgoal =
    case ( mcur, mgoal ) of
        ( Just cur, Just goal ) ->
            let
                dt =
                    cur - goal

                sign =
                    if dt >= 0 then
                        "+"

                    else
                        ""
            in
            span [] [ text <| " (" ++ sign ++ formatDuration dt ++ ")" ]

        _ ->
            span [] []


formatMaybeDuration : Maybe Duration -> String
formatMaybeDuration =
    Maybe.Extra.unwrap "--:--" formatDuration
