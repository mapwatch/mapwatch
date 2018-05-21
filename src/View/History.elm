module View.History exposing (view)

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
import View.Setup
import View.NotFound
import View.Home exposing (maskedText, viewHeader, viewParseError, viewProgress, viewInstance, viewDate, formatDuration, formatSideAreaType, viewSideAreaName)


view : Int -> Model -> H.Html Msg
view page model =
    if isValidPage page model then
        H.div []
            [ viewHeader
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
        -- [ viewStats "Today" (Run.filterToday model.now model.runs)
        -- , viewStats "All-time" model.runs
        [ viewTable page model
        ]


viewStatsDurations : Run.DurationSet -> H.Html msg
viewStatsDurations =
    H.text << toString


viewStats : String -> List Run -> H.Html msg
viewStats title runs =
    H.div []
        [ H.text <| title ++ ": " ++ toString (List.length runs) ++ " runs"
        , viewStatsDurations (Run.totalDurationSet runs)
        , viewStatsDurations (Run.meanDurationSet runs)
        ]


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


viewTable : Int -> Model -> H.Html msg
viewTable page model =
    let
        paginator =
            viewPaginator page (List.length model.runs)

        runs =
            model.runs
                |> List.drop (page * perPage)
                |> List.take perPage
    in
        H.table []
            [ H.thead []
                [ H.tr [] [ H.td [ A.colspan 11 ] [ paginator ] ]

                -- , viewHistoryHeader
                ]
            , H.tbody [] (runs |> List.map viewHistoryRun |> List.concat)
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


viewHistoryRun : Run -> List (H.Html msg)
viewHistoryRun r =
    viewHistoryMainRow r :: (List.map (uncurry viewHistorySideAreaRow) (Run.durationPerSideArea r))


pluralize : String -> String -> number -> String
pluralize one other n =
    if n == 1 then
        one
    else
        other


viewHistoryMainRow : Run -> H.Html msg
viewHistoryMainRow r =
    let
        d =
            Run.durationSet r
    in
        H.tr [ A.class "main-area" ]
            ([ H.td [ A.class "date" ] [ viewDate r.last.leftAt ]
             , H.td [ A.class "zone" ] [ viewInstance r.first.instance ]
             , H.td [ A.class "total-dur" ] [ viewDuration d.all, H.text " total " ]
             , H.td [] [ H.text " = " ]
             , H.td [] [ viewDuration d.start, H.text " map " ]
             , H.td [] [ H.text " + " ]
             , H.td [] [ viewDuration d.town, H.text " town " ]
             ]
                ++ (if d.subs > 0 then
                        [ H.td [] [ H.text " + " ]
                        , H.td [] [ viewDuration d.subs, H.text " side" ]
                        ]
                    else
                        [ H.td [] [], H.td [] [] ]
                   )
                ++ [ H.td [ A.class "portals" ] [ H.text <| toString d.portals ++ pluralize " portal" " portals" d.portals ]
                   , H.td [ A.class "town-pct" ]
                        [ H.text <| toString (clamp 0 100 <| floor <| 100 * (d.town / (max 1 d.all))) ++ "% in town" ]
                   ]
            )


viewHistorySideAreaRow : Instance -> Time.Time -> H.Html msg
viewHistorySideAreaRow instance d =
    H.tr [ A.class "side-area" ]
        [ H.td [ A.class "date" ] []
        , H.td [] []
        , H.td [ A.class "zone", A.colspan 6 ] [ viewSideAreaName (Just instance) ]
        , H.td [ A.class "side-dur" ] [ viewDuration d ]
        , H.td [ A.class "portals" ] []
        , H.td [ A.class "town-pct" ] []
        ]
