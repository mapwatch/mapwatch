module View.History exposing (formatMaybeDuration, view, viewDurationDelta, viewHistoryRun)

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch as Mapwatch
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.RawRun as RawRun exposing (RawRun)
import Mapwatch.Run2 as Run2 exposing (Run2)
import Mapwatch.Run2.Conqueror as Conqueror
import Mapwatch.Run2.Sort as RunSort
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Regex
import Route
import Set exposing (Set)
import Time exposing (Posix)
import View.Home exposing (formatDuration, maskedText, viewDate, viewHeader, viewProgress, viewRegion, viewRun, viewSideAreaName)
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
        currentRun : Maybe Run2
        currentRun =
            -- include the current run if we're viewing a snapshot
            Maybe.andThen (\b -> model.mapwatch.runState |> RawRun.current b model.mapwatch.instance) params.before
                |> Maybe.map Run2.fromRaw

        searchFilter : List Run2 -> List Run2
        searchFilter =
            Maybe.Extra.unwrap identity (RunSort.search model.mapwatch.datamine) params.search

        runs : List Run2
        runs =
            Maybe.Extra.unwrap model.mapwatch.runs (\r -> r :: model.mapwatch.runs) currentRun
                |> searchFilter
                |> RunSort.filterBetween params
                |> RunSort.sort params.sort
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


viewStatsTable : Route.HistoryParams -> Time.Zone -> Posix -> List Run2 -> Html msg
viewStatsTable qs tz now runs =
    table [ class "history-stats" ]
        [ tbody []
            (case ( qs.after, qs.before ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (text "Today") (runs |> RunSort.filterToday tz now |> Run2.aggregate)
                        , viewStatsRows (text "All-time") (runs |> Run2.aggregate)
                        ]

                _ ->
                    viewStatsRows (text "This session") (runs |> RunSort.filterBetween qs |> Run2.aggregate)
            )
        ]


viewStatsRows : Html msg -> Run2.Aggregate -> List (Html msg)
viewStatsRows title runs =
    [ tr []
        [ th [ class "title" ] [ title ]
        , td [ colspan 10, class "maps-completed" ] [ text <| String.fromInt runs.num ++ pluralize " map" " maps" runs.num ++ " completed" ]
        ]
    , tr []
        ([ td [] []
         , td [] [ text "Average time per map" ]
         ]
            ++ viewDurationAggregate runs.mean
        )
    , tr []
        ([ td [] []
         , td [] [ text "Total time" ]
         ]
            ++ viewDurationAggregate { portals = toFloat runs.total.portals, duration = runs.total.duration }
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


viewHistoryTable : Route.HistoryParams -> List Run2 -> OkModel -> Html msg
viewHistoryTable ({ page } as params) queryRuns model =
    let
        paginator =
            viewPaginator params (List.length queryRuns)

        pageRuns =
            queryRuns
                |> List.drop (page * perPage)
                |> List.take perPage

        goalDuration =
            RunSort.goalDuration (RunSort.parseGoalDuration params.goal)
                { session =
                    case params.after of
                        Just _ ->
                            queryRuns

                        Nothing ->
                            RunSort.filterToday model.tz model.now model.mapwatch.runs
                , allTime = model.mapwatch.runs
                }
    in
    table [ class "history" ]
        [ thead []
            [ tr [] [ td [ colspan 12 ] [ paginator ] ]

            -- , viewHistoryHeader (Run.parseSort params.sort) params
            ]
        , tbody [] (pageRuns |> List.map (viewHistoryRun model.tz { showDate = True } params goalDuration) |> List.concat)
        , tfoot [] [ tr [] [ td [ colspan 12 ] [ paginator ] ] ]
        ]


viewSortLink : RunSort.SortField -> ( RunSort.SortField, RunSort.SortDir ) -> Route.HistoryParams -> Html msg
viewSortLink thisField ( sortedField, dir ) qs =
    let
        ( icon, slug ) =
            if thisField == sortedField then
                -- already sorted on this field, link changes direction
                ( Icon.fas
                    (if dir == RunSort.Asc then
                        "sort-up"

                     else
                        "sort-down"
                    )
                , RunSort.stringifySort thisField <| Just <| RunSort.reverseSort dir
                )

            else
                -- link sorts by this field with default direction
                ( Icon.fas "sort", RunSort.stringifySort thisField Nothing )
    in
    a [ Route.href <| Route.History { qs | sort = Just slug } ] [ icon ]


viewHistoryHeader : ( RunSort.SortField, RunSort.SortDir ) -> Route.HistoryParams -> Html msg
viewHistoryHeader sort qs =
    let
        link field =
            viewSortLink field sort qs
    in
    tr []
        [ th [] [ link RunSort.SortDate ]
        , th [ class "zone" ] [ link RunSort.Name ]
        , th [] [ link RunSort.Region ]
        , th [] [ link RunSort.TimeTotal ]
        , th [] []
        , th [] [ link RunSort.TimeMap ]
        , th [] []
        , th [] [ link RunSort.TimeTown ]
        , th [] []
        , th [] [ link RunSort.TimeSide ]
        , th [] [ link RunSort.Portals ]
        , th [] []
        ]


viewDuration =
    text << formatDuration


type alias HistoryRowConfig =
    { showDate : Bool }


type alias Duration =
    Int


viewHistoryRun : Time.Zone -> HistoryRowConfig -> Route.HistoryParams -> (Run2 -> Maybe Duration) -> Run2 -> List (Html msg)
viewHistoryRun tz config qs goals r =
    viewHistoryMainRow tz config qs (goals r) r
        :: List.concat
            [ r.sideAreas
                |> Dict.values
                |> List.map (viewHistorySideAreaRow config qs)
            , r.conqueror
                |> Maybe.map (viewConquerorRow config)
                |> Maybe.Extra.toList
            , r.npcs
                |> Set.toList
                |> List.filterMap (viewHistoryNpcTextRow config qs)
            ]


viewDurationAggregate : { a | portals : Float, duration : Run2.Durations } -> List (Html msg)
viewDurationAggregate a =
    [ td [ class "dur total-dur" ] [ viewDuration a.duration.all ] ]
        ++ viewDurationTail a


viewRunDurations : Maybe Duration -> Run2 -> List (Html msg)
viewRunDurations goal run =
    [ td [ class "dur total-dur" ] [ viewDuration run.duration.all ]
    , td [ class "dur delta-dur" ] [ viewDurationDelta (Just run.duration.all) goal ]
    ]
        ++ viewDurationTail { portals = toFloat run.portals, duration = run.duration }


viewDurationTail : { a | portals : Float, duration : Run2.Durations } -> List (Html msg)
viewDurationTail { portals, duration } =
    [ td [ class "dur" ] [ text " = " ]
    , td [ class "dur" ] [ viewDuration duration.mainMap, text " in map " ]
    , td [ class "dur" ] [ text " + " ]
    , td [ class "dur" ] [ viewDuration duration.town, text " in town " ]
    ]
        ++ (if duration.sides > 0 then
                [ td [ class "dur" ] [ text " + " ]
                , td [ class "dur" ] [ viewDuration duration.sides, text " in sides" ]
                ]

            else
                [ td [ class "dur" ] [], td [ class "dur" ] [] ]
           )
        ++ [ td [ class "portals" ] [ text <| String.fromFloat (roundToPlaces 2 portals) ++ pluralize " portal" " portals" portals ]
           , td [ class "town-pct" ]
                [ text <| String.fromInt (clamp 0 100 <| floor <| 100 * (toFloat duration.town / Basics.max 1 (toFloat duration.all))) ++ "% in town" ]
           ]


viewHistoryMainRow : Time.Zone -> HistoryRowConfig -> Route.HistoryParams -> Maybe Duration -> Run2 -> Html msg
viewHistoryMainRow tz { showDate } qs goal r =
    tr [ class "main-area" ]
        ((if showDate then
            [ td [ class "date" ] [ viewDate tz r.updatedAt ] ]

          else
            []
         )
            ++ [ td [ class "zone" ] [ viewRun qs r ]
               , td [] [ viewRegion qs r.address.worldArea ]
               ]
            ++ viewRunDurations goal r
        )


viewHistorySideAreaRow : HistoryRowConfig -> Route.HistoryParams -> ( Instance.Address, Duration ) -> Html msg
viewHistorySideAreaRow { showDate } qs ( instance, d ) =
    tr [ class "side-area" ]
        ((if showDate then
            [ td [ class "date" ] [] ]

          else
            []
         )
            ++ [ td [] []
               , td [ class "zone", colspan 8 ] [ viewSideAreaName qs (Instance.Instance instance) ]
               , td [ class "side-dur" ] [ viewDuration d ]
               , td [ class "portals" ] []
               , td [ class "town-pct" ] []
               ]
        )


viewHistoryNpcTextRow : HistoryRowConfig -> Route.HistoryParams -> NpcId -> Maybe (Html msg)
viewHistoryNpcTextRow { showDate } qs npcId =
    case viewNpcText npcId of
        [] ->
            Nothing

        body ->
            Just <|
                tr [ class "npctext-area" ]
                    ((if showDate then
                        [ td [ class "date" ] [] ]

                      else
                        []
                     )
                        ++ [ td [] []

                           -- , td [ colspan 8, title (encounters |> List.reverse |> List.map .raw |> String.join "\n\n") ] body
                           , td [ colspan 8 ] body
                           , td [ class "side-dur" ] []
                           , td [ class "portals" ] []
                           , td [ class "town-pct" ] []
                           ]
                    )


viewNpcText : String -> List (Html msg)
viewNpcText npcId =
    if npcId == NpcId.einhar then
        [ Icon.einhar, text "Einhar, Beastmaster" ]

    else if npcId == NpcId.alva then
        [ Icon.alva, text "Alva, Master Explorer" ]

    else if npcId == NpcId.niko then
        [ Icon.niko, text "Niko, Master of the Depths" ]

    else if npcId == NpcId.jun then
        [ Icon.jun, text "Jun, Veiled Master" ]

    else if npcId == NpcId.cassia then
        [ Icon.cassia, text "Sister Cassia" ]
        -- Don't show Tane during Metamorph league
        -- else if npcId == NpcId.tane then
        -- [ Icon.tane, text "Tane Octavius" ]

    else
        []


viewConquerorRow : HistoryRowConfig -> ( Conqueror.Id, Conqueror.Encounter ) -> Html msg
viewConquerorRow { showDate } ( id, encounter ) =
    let
        label : List (Html msg)
        label =
            case id of
                Conqueror.Baran ->
                    [ Icon.baran, text "Baran, the Crusader" ]

                Conqueror.Veritania ->
                    [ Icon.veritania, text "Veritania, the Redeemer" ]

                Conqueror.AlHezmin ->
                    [ Icon.alHezmin, text "Al-Hezmin, the Hunter" ]

                Conqueror.Drox ->
                    [ Icon.drox, text "Drox, the Warlord" ]

        body : List (Html msg)
        body =
            case encounter of
                Conqueror.Taunt n ->
                    label ++ [ text <| ": Taunt " ++ String.fromInt n ]

                Conqueror.Fight ->
                    label ++ [ text ": Fight" ]
    in
    tr [ class "npctext-area" ]
        ((if showDate then
            [ td [ class "date" ] [] ]

          else
            []
         )
            ++ [ td [] []
               , td [ colspan 8 ] body
               , td [ class "side-dur" ] []
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
