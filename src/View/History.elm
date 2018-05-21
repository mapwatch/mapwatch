module View.History exposing (view, viewHistoryRun)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Time
import Date
import Dict
import Model as Model exposing (Model, Msg(..))
import Model.Instance as Instance exposing (Instance)
import Model.Run as Run exposing (Run)
import Model.Zone as Zone
import Model.Route as Route
import View.Nav
import View.Setup
import View.NotFound
import View.Home exposing (maskedText, viewHeader, viewParseError, viewProgress, viewInstance, viewDate, formatDuration, formatSideAreaType, viewSideAreaName)


view : Int -> Model -> H.Html Msg
view page model =
    if isValidPage page model then
        H.div []
            [ viewHeader
            , View.Nav.view model.route
            , View.Setup.view model
            , viewParseError model.parseError
            , viewBody page model
            ]
    else
        View.NotFound.view


viewBody : Int -> Model -> H.Html msg
viewBody page model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Model.isProgressDone p then
                    -- all done!
                    [ viewMain page model ]
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


viewMain : Int -> Model -> H.Html msg
viewMain page model =
    H.div []
        [ viewStatsTable model
        , viewHistoryTable page model
        ]


viewStatsTable : Model -> H.Html msg
viewStatsTable model =
    H.table [ A.class "history-stats" ]
        [ H.tbody []
            (List.concat
                [ viewStatsRows "Today" (Run.filterToday model.now model.runs)
                , viewStatsRows "All-time" model.runs
                ]
            )
        ]


viewStatsRows : String -> List Run -> List (H.Html msg)
viewStatsRows title runs =
    [ H.tr []
        [ H.th [ A.class "title" ] [ H.text <| title ]
        , H.td [ A.colspan 10, A.class "maps-completed" ] [ H.text <| toString (List.length runs) ++ " maps completed" ]
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


viewPaginator : Int -> Int -> H.Html msg
viewPaginator page numItems =
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

        href =
            Route.href << Route.History

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
            [ firstLink [ H.text "<< First" ]
            , prevLink [ H.text "< Prev" ]
            , H.span [] [ H.text <| toString firstVisItem ++ " - " ++ toString lastVisItem ++ " of " ++ toString numItems ]
            , nextLink [ H.text "Next >" ]
            , lastLink [ H.text "Last >>" ]
            ]


viewHistoryTable : Int -> Model -> H.Html msg
viewHistoryTable page model =
    let
        paginator =
            viewPaginator page (List.length model.runs)

        runs =
            model.runs
                |> List.drop (page * perPage)
                |> List.take perPage
    in
        H.table [ A.class "history" ]
            [ H.thead []
                [ H.tr [] [ H.td [ A.colspan 11 ] [ paginator ] ]

                -- , viewHistoryHeader
                ]
            , H.tbody [] (runs |> List.map (viewHistoryRun { showDate = True }) |> List.concat)
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


viewHistoryRun : HistoryRowConfig -> Run -> List (H.Html msg)
viewHistoryRun config r =
    viewHistoryMainRow config r :: (List.map (uncurry <| viewHistorySideAreaRow config) (Run.durationPerSideArea r))


pluralize : String -> String -> number -> String
pluralize one other n =
    if n == 1 then
        one
    else
        other


roundToPlaces : Float -> Float -> Float
roundToPlaces p n =
    (n * (10 ^ p) |> round |> toFloat) / (10 ^ p)


viewDurationSet : Run.DurationSet -> List (H.Html msg)
viewDurationSet d =
    [ H.td [ A.class "dur total-dur" ] [ viewDuration d.all ]
    , H.td [ A.class "dur" ] [ H.text " = " ]
    , H.td [ A.class "dur" ] [ viewDuration d.start, H.text " in map " ]
    , H.td [ A.class "dur" ] [ H.text " + " ]
    , H.td [ A.class "dur" ] [ viewDuration d.town, H.text " in town " ]
    ]
        ++ (if d.subs > 0 then
                [ H.td [ A.class "dur" ] [ H.text " + " ]
                , H.td [ A.class "dur" ] [ viewDuration d.subs, H.text " in sides" ]
                ]
            else
                [ H.td [ A.class "dur" ] [], H.td [ A.class "dur" ] [] ]
           )
        ++ [ H.td [ A.class "portals" ] [ H.text <| toString (roundToPlaces 2 d.portals) ++ pluralize " portal" " portals" d.portals ]
           , H.td [ A.class "town-pct" ]
                [ H.text <| toString (clamp 0 100 <| floor <| 100 * (d.town / (max 1 d.all))) ++ "% in town" ]
           ]


viewHistoryMainRow : HistoryRowConfig -> Run -> H.Html msg
viewHistoryMainRow { showDate } r =
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
                ++ [ H.td [ A.class "zone" ] [ viewInstance r.first.instance ]
                   ]
                ++ viewDurationSet d
            )


viewHistorySideAreaRow : HistoryRowConfig -> Instance -> Time.Time -> H.Html msg
viewHistorySideAreaRow { showDate } instance d =
    H.tr [ A.class "side-area" ]
        ((if showDate then
            [ H.td [ A.class "date" ] [] ]
          else
            []
         )
            ++ [ H.td [] []
               , H.td [ A.class "zone", A.colspan 6 ] [ viewSideAreaName (Just instance) ]
               , H.td [ A.class "side-dur" ] [ viewDuration d ]
               , H.td [ A.class "portals" ] []
               , H.td [ A.class "town-pct" ] []
               ]
        )
