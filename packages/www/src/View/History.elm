module View.History exposing (formatMaybeDuration, listRuns, view, viewDurationDelta, viewHistoryRun)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.MapRun.Sort as RunSort
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Model exposing (Msg(..), OkModel)
import Regex
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Time exposing (Posix)
import View.Home
import View.Icon
import View.Nav
import View.NotFound
import View.Setup
import View.Util
import View.Volume


view : OkModel -> Html Msg
view model =
    if Mapwatch.isReady model.mapwatch && not (isValidPage (QueryDict.getInt Route.keys.page model.query |> Maybe.withDefault 0) model) then
        View.NotFound.view model

    else
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

        Mapwatch.Ready p ->
            div []
                [ viewMain model
                , View.Home.viewProgress p
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


listRuns : OkModel -> List MapRun
listRuns model =
    let
        before =
            QueryDict.getPosix Route.keys.before model.query

        after =
            QueryDict.getPosix Route.keys.after model.query

        search =
            Dict.get Route.keys.search model.query

        sort =
            Dict.get Route.keys.sort model.query

        currentRun : Maybe MapRun
        currentRun =
            -- include the current run if we're viewing a snapshot
            before
                |> Maybe.andThen (\b -> model.mapwatch.runState |> RawMapRun.current b model.mapwatch.instance)
                |> Maybe.map MapRun.fromRaw

        searchFilter : List MapRun -> List MapRun
        searchFilter =
            search |> Maybe.Extra.unwrap identity (RunSort.search model.mapwatch.datamine)
    in
    Maybe.Extra.unwrap model.mapwatch.runs (\r -> r :: model.mapwatch.runs) currentRun
        |> searchFilter
        |> RunSort.filterBetween { before = before, after = after }
        |> RunSort.sort sort


viewMain : OkModel -> Html Msg
viewMain model =
    let
        runs =
            listRuns model
    in
    div []
        [ div []
            [ View.Volume.view model
            , View.Util.viewSearch [ placeholder "area name" ] model.query
            , View.Util.viewDateSearch model.query model.route
            , View.Util.viewGoalForm model.query
            ]
        , viewStatsTable model.query model.tz model.now runs
        , viewHistoryTable runs model
        , div []
            [ a [ Route.href model.query Route.HistoryTSV ] [ View.Icon.fas "table", text " Export as TSV" ]
            ]
        ]


viewStatsTable : QueryDict -> Time.Zone -> Posix -> List MapRun -> Html msg
viewStatsTable query tz now runs =
    table [ class "history-stats" ]
        [ tbody []
            (case ( QueryDict.getPosix Route.keys.after query, QueryDict.getPosix Route.keys.before query ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (text "Today") (runs |> RunSort.filterToday tz now |> MapRun.aggregate)
                        , viewStatsRows (text "All-time") (runs |> MapRun.aggregate)
                        ]

                ( a, b ) ->
                    viewStatsRows (text "This session") (runs |> RunSort.filterBetween { before = b, after = a } |> MapRun.aggregate)
            )
        ]


viewStatsRows : Html msg -> MapRun.Aggregate -> List (Html msg)
viewStatsRows title runs =
    [ tr []
        [ th [ class "title" ] [ title ]
        , td [ colspan 10, class "maps-completed" ] [ text <| String.fromInt runs.num ++ View.Util.pluralize " map" " maps" runs.num ++ " completed" ]
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


viewPaginator : QueryDict -> Int -> Html msg
viewPaginator query numItems =
    let
        page =
            QueryDict.getInt Route.keys.page query |> Maybe.withDefault 0

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
            let
                q =
                    if i == 0 then
                        Dict.remove Route.keys.page query

                    else
                        QueryDict.insertInt Route.keys.page i query
            in
            Route.href q Route.History

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
        [ firstLink [ View.Icon.fas "fast-backward", text " First" ]
        , prevLink [ View.Icon.fas "step-backward", text " Prev" ]
        , span [] [ text <| String.fromInt firstVisItem ++ " - " ++ String.fromInt lastVisItem ++ " of " ++ String.fromInt numItems ]
        , nextLink [ text "Next ", View.Icon.fas "step-forward" ]
        , lastLink [ text "Last ", View.Icon.fas "fast-forward" ]
        ]


viewHistoryTable : List MapRun -> OkModel -> Html msg
viewHistoryTable queryRuns model =
    let
        page =
            QueryDict.getInt Route.keys.page model.query |> Maybe.withDefault 0

        paginator =
            viewPaginator model.query (List.length queryRuns)

        pageRuns =
            queryRuns
                |> List.drop (page * perPage)
                |> List.take perPage

        goalDuration =
            RunSort.goalDuration (RunSort.parseGoalDuration <| Dict.get Route.keys.goal model.query)
                { session =
                    case QueryDict.getPosix Route.keys.after model.query of
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
        , tbody [] (pageRuns |> List.map (viewHistoryRun model { showDate = True } goalDuration) |> List.concat)
        , tfoot [] [ tr [] [ td [ colspan 12 ] [ paginator ] ] ]
        ]


viewSortLink : QueryDict -> RunSort.SortField -> ( RunSort.SortField, RunSort.SortDir ) -> Html msg
viewSortLink query thisField ( sortedField, dir ) =
    let
        ( icon, slug ) =
            if thisField == sortedField then
                -- already sorted on this field, link changes direction
                ( View.Icon.fas
                    (if dir == RunSort.Asc then
                        "sort-up"

                     else
                        "sort-down"
                    )
                , RunSort.stringifySort thisField <| Just <| RunSort.reverseSort dir
                )

            else
                -- link sorts by this field with default direction
                ( View.Icon.fas "sort", RunSort.stringifySort thisField Nothing )
    in
    a [ Route.href (Dict.insert Route.keys.sort slug query) Route.History ] [ icon ]


viewHistoryHeader : QueryDict -> ( RunSort.SortField, RunSort.SortDir ) -> Html msg
viewHistoryHeader query sort =
    let
        link field =
            viewSortLink query field sort
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
    text << View.Home.formatDuration


type alias HistoryRowConfig =
    { showDate : Bool }


type alias Duration =
    Int


viewHistoryRun : { m | query : QueryDict, tz : Time.Zone } -> HistoryRowConfig -> (MapRun -> Maybe Duration) -> MapRun -> List (Html msg)
viewHistoryRun ({ query, tz } as m) config goals r =
    viewHistoryMainRow m config (goals r) r
        :: List.concat
            [ r.sideAreas
                |> Dict.values
                |> List.map (viewHistorySideAreaRow query config)
            , r.conqueror
                |> Maybe.map (viewConquerorRow config r.npcSays)
                |> Maybe.Extra.toList
            , r.npcSays
                |> Dict.toList
                |> List.filterMap (viewHistoryNpcTextRow config)
            ]


viewDurationAggregate : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
viewDurationAggregate a =
    [ td [ class "dur total-dur" ] [ viewDuration a.duration.all ] ]
        ++ viewDurationTail a


viewRunDurations : Maybe Duration -> MapRun -> List (Html msg)
viewRunDurations goal run =
    [ td [ class "dur total-dur" ] [ viewDuration run.duration.all ]
    , td [ class "dur delta-dur" ] [ viewDurationDelta (Just run.duration.all) goal ]
    ]
        ++ viewDurationTail { portals = toFloat run.portals, duration = run.duration }


viewDurationTail : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
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
        ++ [ td [ class "portals" ] [ text <| String.fromFloat (View.Util.roundToPlaces 2 portals) ++ View.Util.pluralize " portal" " portals" portals ]
           , td [ class "town-pct" ]
                [ text <| String.fromInt (clamp 0 100 <| floor <| 100 * (toFloat duration.town / Basics.max 1 (toFloat duration.all))) ++ "% in town" ]
           ]


viewHistoryMainRow : { m | query : QueryDict, tz : Time.Zone } -> HistoryRowConfig -> Maybe Duration -> MapRun -> Html msg
viewHistoryMainRow { tz, query } { showDate } goal r =
    tr [ class "main-area" ]
        ((if showDate then
            [ td [ class "date" ] [ View.Home.viewDate tz r.updatedAt ] ]

          else
            []
         )
            ++ [ td [ class "zone" ] [ View.Home.viewRun query r ]
               , td [] [ View.Home.viewRegion query r.address.worldArea ]
               ]
            ++ viewRunDurations goal r
        )


viewHistorySideAreaRow : QueryDict -> HistoryRowConfig -> ( Instance.Address, Duration ) -> Html msg
viewHistorySideAreaRow query { showDate } ( instance, d ) =
    tr [ class "side-area" ]
        ((if showDate then
            [ td [ class "date" ] [] ]

          else
            []
         )
            ++ [ td [] []
               , td [] []
               , td [ class "zone", colspan 7 ] [ View.Home.viewSideAreaName query (Instance.Instance instance) ]
               , td [ class "side-dur" ] [ viewDuration d ]
               , td [ class "portals" ] []
               , td [ class "town-pct" ] []
               ]
        )


viewHistoryNpcTextRow : HistoryRowConfig -> ( NpcId, List String ) -> Maybe (Html msg)
viewHistoryNpcTextRow { showDate } ( npcId, texts ) =
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
                           , td [] []

                           -- , td [ colspan 7, title (encounters |> List.reverse |> List.map .raw |> String.join "\n\n") ] body
                           , td [ colspan 7, title <| String.join "\n\n" texts ] body
                           , td [ class "side-dur" ] []
                           , td [ class "portals" ] []
                           , td [ class "town-pct" ] []
                           ]
                    )


viewNpcText : String -> List (Html msg)
viewNpcText npcId =
    if npcId == NpcId.einhar then
        [ View.Icon.einhar, text "Einhar, Beastmaster" ]

    else if npcId == NpcId.alva then
        [ View.Icon.alva, text "Alva, Master Explorer" ]

    else if npcId == NpcId.niko then
        [ View.Icon.niko, text "Niko, Master of the Depths" ]

    else if npcId == NpcId.jun then
        [ View.Icon.jun, text "Jun, Veiled Master" ]

    else if npcId == NpcId.cassia then
        [ View.Icon.cassia, text "Sister Cassia" ]
        -- Don't show Tane during Metamorph league
        -- else if npcId == NpcId.tane then
        -- [ View.Icon.tane, text "Tane Octavius" ]
        -- Don't show conquerors, they have their own special function

    else
        []


viewConquerorRow : HistoryRowConfig -> Dict NpcId (List String) -> ( Conqueror.Id, Conqueror.Encounter ) -> Html msg
viewConquerorRow { showDate } npcSays ( id, encounter ) =
    let
        says : List String
        says =
            Dict.get (Conqueror.npcFromId id) npcSays |> Maybe.withDefault []

        label : List (Html msg)
        label =
            case id of
                Conqueror.Baran ->
                    [ View.Icon.baran, text "Baran, the Crusader" ]

                Conqueror.Veritania ->
                    [ View.Icon.veritania, text "Veritania, the Redeemer" ]

                Conqueror.AlHezmin ->
                    [ View.Icon.alHezmin, text "Al-Hezmin, the Hunter" ]

                Conqueror.Drox ->
                    [ View.Icon.drox, text "Drox, the Warlord" ]

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
               , td [] []
               , td [ colspan 7, title <| String.join "\n\n" says ] body
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
            span [] [ text <| " (" ++ sign ++ View.Home.formatDuration dt ++ ")" ]

        _ ->
            span [] []


formatMaybeDuration : Maybe Duration -> String
formatMaybeDuration =
    Maybe.Extra.unwrap "--:--" View.Home.formatDuration
