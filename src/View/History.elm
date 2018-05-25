module View.History exposing (view, viewHistoryRun, viewDurationSet)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Time
import Date
import Dict
import Regex
import Maybe.Extra
import Model as Model exposing (Model, Msg(..))
import Model.Instance as Instance exposing (Instance)
import Model.Run as Run exposing (Run)
import Model.Zone as Zone
import Model.Route as Route
import View.Nav
import View.Setup
import View.NotFound
import View.Home exposing (maskedText, viewHeader, viewParseError, viewProgress, viewInstance, viewDate, formatDuration, formatSideAreaType, viewSideAreaName)
import View.Icon as Icon
import View.Util exposing (roundToPlaces, viewSearch, pluralize)


view : Route.HistoryParams -> Model -> H.Html Msg
view params model =
    if Model.isReady model && not (isValidPage params.page model) then
        View.NotFound.view
    else
        H.div []
            [ viewHeader
            , View.Nav.view <| Just model.route
            , View.Setup.view model
            , viewParseError model.parseError
            , viewBody params model
            ]


viewBody : Route.HistoryParams -> Model -> H.Html Msg
viewBody params model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Model.isProgressDone p then
                    -- all done!
                    [ viewMain params model ]
                 else
                    []
                )
                    ++ [ viewProgress p ]


perPage =
    25


numPages : Int -> Int
numPages numItems =
    ceiling <| (toFloat numItems) / (toFloat perPage)


isValidPage : Int -> Model -> Bool
isValidPage page model =
    case model.progress of
        Nothing ->
            True

        Just _ ->
            page == (clamp 0 (numPages (List.length model.runs) - 1) page)


viewMain : Route.HistoryParams -> Model -> H.Html Msg
viewMain params model =
    let
        currentRun : Maybe Run
        currentRun =
            -- include the current run if we're viewing a snapshot
            Maybe.andThen (\b -> Run.current b model.instance model.runState) params.before

        runs =
            model.runs
                |> (++) (Maybe.Extra.toList currentRun)
                |> Maybe.Extra.unwrap identity Run.search params.search
                |> Run.filterBetween params
                |> Maybe.Extra.unwrap identity Run.sort params.sort
    in
        H.div []
            [ H.div []
                [ viewSearch [ A.placeholder "area name" ]
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
                ]
            , viewStatsTable params model.now runs
            , viewHistoryTable params runs
            ]


viewStatsTable : Route.HistoryParams -> Date.Date -> List Run -> H.Html msg
viewStatsTable qs now runs =
    H.table [ A.class "history-stats" ]
        [ H.tbody []
            (case ( qs.after, qs.before ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (H.text "Today") (Run.filterToday now runs)
                        , viewStatsRows (H.text "All-time") runs
                        ]

                _ ->
                    viewStatsRows (H.text "This session") (Run.filterBetween qs runs)
            )
        ]


viewStatsRows : H.Html msg -> List Run -> List (H.Html msg)
viewStatsRows title runs =
    [ H.tr []
        [ H.th [ A.class "title" ] [ title ]
        , H.td [ A.colspan 10, A.class "maps-completed" ] [ H.text <| toString (List.length runs) ++ pluralize " map" " maps" (List.length runs) ++ " completed" ]
        ]
    , H.tr []
        ([ H.td [] []
         , H.td [] [ H.text "Average time per map" ]
         ]
            ++ viewDurationSet (Run.meanDurationSet runs)
        )
    , H.tr []
        ([ H.td [] []
         , H.td [] [ H.text "Total time" ]
         ]
            ++ viewDurationSet (Run.totalDurationSet runs)
        )
    ]



--[ H.div []
--    [ H.text <|
--    , viewStatsDurations (Run.totalDurationSet runs)
--    , viewStatsDurations (Run.meanDurationSet runs)
--    ]
--]


viewStatsDurations : Run.DurationSet -> H.Html msg
viewStatsDurations =
    H.text << toString


viewPaginator : Route.HistoryParams -> Int -> H.Html msg
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
                ( H.a [ href 0 ], H.a [ href prev ] )
            else
                ( H.span [], H.span [] )

        ( nextLink, lastLink ) =
            if page /= last then
                ( H.a [ href next ], H.a [ href last ] )
            else
                ( H.span [], H.span [] )
    in
        H.div [ A.class "paginator" ]
            [ firstLink [ Icon.fas "fast-backward", H.text " First" ]
            , prevLink [ Icon.fas "step-backward", H.text " Prev" ]
            , H.span [] [ H.text <| toString firstVisItem ++ " - " ++ toString lastVisItem ++ " of " ++ toString numItems ]
            , nextLink [ H.text "Next ", Icon.fas "step-forward" ]
            , lastLink [ H.text "Last ", Icon.fas "fast-forward" ]
            ]


viewHistoryTable : Route.HistoryParams -> List Run -> H.Html msg
viewHistoryTable ({ page } as params) queryRuns =
    let
        paginator =
            viewPaginator params (List.length queryRuns)

        pageRuns =
            queryRuns
                |> List.drop (page * perPage)
                |> List.take perPage
    in
        H.table [ A.class "history" ]
            [ H.thead []
                [ H.tr [] [ H.td [ A.colspan 11 ] [ paginator ] ]

                -- , viewHistoryHeader
                ]
            , H.tbody [] (pageRuns |> List.map (viewHistoryRun { showDate = True } params) |> List.concat)
            , H.tfoot [] [ H.tr [] [ H.td [ A.colspan 11 ] [ paginator ] ] ]
            ]


viewHistoryHeader : H.Html msg
viewHistoryHeader =
    H.tr []
        -- [ H.th [] [ H.text "Date" ]
        -- , H.th [] []
        [ H.th [] [ H.text "Zone" ]
        , H.th [] [ H.text "Total" ]
        , H.th [] []
        , H.th [] [ H.text "Main" ]
        , H.th [] []
        , H.th [] [ H.text "Side" ]
        , H.th [] []
        , H.th [] [ H.text "Town" ]
        ]


viewDuration =
    H.text << formatDuration


type alias HistoryRowConfig =
    { showDate : Bool }


viewHistoryRun : HistoryRowConfig -> Route.HistoryParams -> Run -> List (H.Html msg)
viewHistoryRun config qs r =
    viewHistoryMainRow config qs r :: (List.map (uncurry <| viewHistorySideAreaRow config qs) (Run.durationPerSideArea r))


viewDurationSet : Run.DurationSet -> List (H.Html msg)
viewDurationSet d =
    [ H.td [ A.class "dur total-dur" ] [ viewDuration d.all ]
    , H.td [ A.class "dur" ] [ H.text " = " ]
    , H.td [ A.class "dur" ] [ viewDuration d.mainMap, H.text " in map " ]
    , H.td [ A.class "dur" ] [ H.text " + " ]
    , H.td [ A.class "dur" ] [ viewDuration d.town, H.text " in town " ]
    ]
        ++ (if d.sides > 0 then
                [ H.td [ A.class "dur" ] [ H.text " + " ]
                , H.td [ A.class "dur" ] [ viewDuration d.sides, H.text " in sides" ]
                ]
            else
                [ H.td [ A.class "dur" ] [], H.td [ A.class "dur" ] [] ]
           )
        ++ [ H.td [ A.class "portals" ] [ H.text <| toString (roundToPlaces 2 d.portals) ++ pluralize " portal" " portals" d.portals ]
           , H.td [ A.class "town-pct" ]
                [ H.text <| toString (clamp 0 100 <| floor <| 100 * (d.town / (max 1 d.all))) ++ "% in town" ]
           ]


viewHistoryMainRow : HistoryRowConfig -> Route.HistoryParams -> Run -> H.Html msg
viewHistoryMainRow { showDate } qs r =
    let
        d =
            Run.durationSet r
    in
        H.tr [ A.class "main-area" ]
            ((if showDate then
                [ H.td [ A.class "date" ] [ viewDate r.last.leftAt ] ]
              else
                []
             )
                ++ [ H.td [ A.class "zone" ] [ viewInstance qs r.first.instance ]
                   ]
                ++ viewDurationSet d
            )


viewHistorySideAreaRow : HistoryRowConfig -> Route.HistoryParams -> Instance -> Time.Time -> H.Html msg
viewHistorySideAreaRow { showDate } qs instance d =
    H.tr [ A.class "side-area" ]
        ((if showDate then
            [ H.td [ A.class "date" ] [] ]
          else
            []
         )
            ++ [ H.td [] []
               , H.td [ A.class "zone", A.colspan 6 ] [ viewSideAreaName qs <| Just instance ]
               , H.td [ A.class "side-dur" ] [ viewDuration d ]
               , H.td [ A.class "portals" ] []
               , H.td [ A.class "town-pct" ] []
               ]
        )
