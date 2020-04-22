module View.History exposing (formatMaybeDuration, listRuns, view, viewDurationDelta, viewHistoryRun)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Json.Encode as Json
import Localized
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine)
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
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Time exposing (Posix)
import View.Home
import View.Icon
import View.Nav
import View.NotFound
import View.Setup
import View.Util


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
                |> Maybe.map (MapRun.fromRaw model.mapwatch.datamine)

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
            [ View.Util.viewSearch [] model.query
            , View.Util.viewDateSearch model.query model.route
            , View.Util.viewGoalForm model.query
            ]
        , div []
            (if Feature.isActive Feature.GSheets model.query then
                [ Localized.text0 "history-export-header"
                , a [ Route.href model.query Route.HistoryTSV ] [ View.Icon.fas "table", text " ", Localized.text0 "history-export-tsv" ]
                , text " | "
                , a [ Route.href model.query Route.GSheets ] [ View.Icon.fab "google-drive", text " ", Localized.text0 "history-export-gsheets" ]
                ]

             else
                [ a [ Route.href model.query Route.HistoryTSV ] [ View.Icon.fas "table", text " ", Localized.text0 "history-export-onlytsv" ] ]
            )
        , viewStatsTable model.query model.tz model.now runs
        , viewHistoryTable runs model
        ]


viewStatsTable : QueryDict -> Time.Zone -> Posix -> List MapRun -> Html msg
viewStatsTable query tz now runs =
    table [ class "history-stats" ]
        [ tbody []
            (case ( QueryDict.getPosix Route.keys.after query, QueryDict.getPosix Route.keys.before query ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (Localized.text0 "history-summary-today") (runs |> RunSort.filterToday tz now |> MapRun.aggregate)
                        , viewStatsRows (Localized.text0 "history-summary-alltime") (runs |> MapRun.aggregate)
                        ]

                ( a, b ) ->
                    viewStatsRows (Localized.text0 "history-summary-session") (runs |> RunSort.filterBetween { before = b, after = a } |> MapRun.aggregate)
            )
        ]


viewStatsRows : Html msg -> MapRun.Aggregate -> List (Html msg)
viewStatsRows title runs =
    [ tr []
        [ th [ class "title" ] [ title ]
        , td [ colspan 10, class "maps-completed" ]
            [ Localized.text "history-summary-completed" [ Localized.int "count" runs.num ]
            ]
        ]
    , tr []
        ([ td [] []
         , td [] [ Localized.text0 "history-summary-meandur" ]
         ]
            ++ viewDurationAggregate runs.mean
        )
    , tr []
        ([ td [] []
         , td [] [ Localized.text0 "history-summary-totaldur" ]
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
        [ firstLink [ View.Icon.fas "fast-backward", text " ", Localized.text0 "history-page-first" ]
        , prevLink [ View.Icon.fas "step-backward", text " ", Localized.text0 "history-page-prev" ]
        , span []
            [ Localized.text "history-page-count"
                [ Localized.int "pageStart" firstVisItem
                , Localized.int "pageEnd" lastVisItem
                , Localized.int "total" numItems
                ]
            ]
        , nextLink [ Localized.text0 "history-page-next", text " ", View.Icon.fas "step-forward" ]
        , lastLink [ Localized.text0 "history-page-last", text " ", View.Icon.fas "fast-forward" ]
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


viewHistoryRun : { m | query : QueryDict, tz : Time.Zone, mapwatch : { mm | datamine : Datamine } } -> HistoryRowConfig -> (MapRun -> Maybe Duration) -> MapRun -> List (Html msg)
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
                |> List.filterMap (viewHistoryNpcTextRow query config)
            ]


viewDurationAggregate : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
viewDurationAggregate a =
    [ td [ class "dur total-dur" ] [ viewDuration a.duration.all ] ]
        ++ viewDurationTail a


viewRunDurations : Maybe Duration -> MapRun -> List (Html msg)
viewRunDurations goal run =
    [ td [ class "dur total-dur" ]
        [ if run.isAbandoned then
            Localized.element "history-row-totaldur-abandoned" [ "title" ] [] <|
                span [ class "abandoned-run-duration" ] []

          else
            viewDuration run.duration.all
        ]
    , td [ class "dur delta-dur" ] [ viewDurationDelta (Just run.duration.all) goal ]
    ]
        ++ viewDurationTail { portals = toFloat run.portals, duration = run.duration }


viewDurationTail : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
viewDurationTail { portals, duration } =
    [ td [ class "dur" ] [ text " = " ]
    , td [ class "dur" ] [ Localized.text "history-row-duration-map" [ Localized.string "duration" <| View.Home.formatDuration duration.mainMap ] ]
    , td [ class "dur" ] [ text " + " ]
    , td [ class "dur" ] [ Localized.text "history-row-duration-town" [ Localized.string "duration" <| View.Home.formatDuration duration.town ] ]
    ]
        ++ (if duration.sides > 0 then
                [ td [ class "dur" ] [ text " + " ]
                , td [ class "dur" ] [ Localized.text "history-row-duration-sides" [ Localized.string "duration" <| View.Home.formatDuration duration.sides ] ]
                ]

            else
                [ td [ class "dur" ] [], td [ class "dur" ] [] ]
           )
        ++ [ td [ class "portals" ] [ Localized.text "history-row-portals" [ Localized.float "count" portals ] ]
           , td [ class "town-pct" ] [ Localized.text "history-row-townpct" [ Localized.float "percent" <| clamp 0.0 1.0 <| toFloat duration.town / Basics.max 1 (toFloat duration.all) ] ]
           ]


viewHistoryMainRow : { m | query : QueryDict, tz : Time.Zone, mapwatch : { mm | datamine : Datamine } } -> HistoryRowConfig -> Maybe Duration -> MapRun -> Html msg
viewHistoryMainRow ({ tz, query } as m) { showDate } goal r =
    tr [ class "main-area" ]
        ((if showDate then
            [ td [ class "date", title <| ISO8601.toString <| ISO8601.fromPosix r.updatedAt ]
                [ Localized.text "history-row-date" [ Localized.int "date" <| Time.posixToMillis r.updatedAt ] ]
            ]

          else
            []
         )
            ++ [ td [ class "zone" ] [ View.Home.viewRun query r ]
               , td []
                    [ Localized.element "history-row-region" [ "title" ] [ Localized.string "body" <| RunSort.searchString m.mapwatch.datamine r ] <|
                        View.Home.viewRegion query r.address.worldArea
                    ]
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
               , td [ class "zone", colspan 7 ] [ viewSideAreaName query (Instance.Instance instance) ]
               , td [ class "side-dur" ] [ viewDuration d ]
               , td [ class "portals" ] []
               , td [ class "town-pct" ] []
               ]
        )


viewSideAreaName : QueryDict -> Instance -> Html msg
viewSideAreaName query instance =
    let
        label =
            View.Home.viewInstance query instance
    in
    case Instance.worldArea instance of
        Nothing ->
            label

        Just w ->
            if Datamine.isMap w then
                span [] [ View.Icon.zana, Localized.text0 "history-side-zana", text " (", label, text ")" ]

            else if w.isVaalArea then
                span [] [ View.Icon.vaal, Localized.text0 "history-side-vaalarea", text " (", label, text ")" ]

            else if w.isLabTrial then
                span [] [ View.Icon.labTrial, Localized.text0 "history-side-labtrial", text " (", label, text ")" ]

            else if w.isAbyssalDepths then
                span [] [ View.Icon.abyss, label ]

            else
                label


viewHistoryNpcTextRow : QueryDict -> HistoryRowConfig -> ( NpcId, List String ) -> Maybe (Html msg)
viewHistoryNpcTextRow query { showDate } ( npcId, texts ) =
    case viewNpcText query npcId of
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


viewNpcText : QueryDict -> String -> List (Html msg)
viewNpcText query npcId =
    if npcId == NpcId.einhar then
        [ View.Icon.einhar, Localized.text0 "history-npc-einhar" ]

    else if npcId == NpcId.alva then
        [ View.Icon.alva, Localized.text0 "history-npc-alva" ]

    else if npcId == NpcId.niko then
        [ View.Icon.niko, Localized.text0 "history-npc-niko" ]

    else if npcId == NpcId.betrayalGroup then
        -- else if npcId == NpcId.jun then
        [ View.Icon.jun, Localized.text0 "history-npc-jun" ]

    else if npcId == NpcId.cassia then
        [ View.Icon.cassia, Localized.text0 "history-npc-cassia" ]
        -- Don't show Tane during Metamorph league
        -- Actually, his voicing is so inconsistent that we can't show him after metamorph league either!
        -- else if npcId == NpcId.tane then
        -- [ View.Icon.tane, Localized.text0 "history-npc-tane" ]
        -- Don't show conquerors, they have their own special function

    else if npcId == NpcId.delirium && Feature.isActive Feature.DeliriumEncounter query then
        [ View.Icon.delirium, Localized.text0 "history-npc-delirium" ]

    else if npcId == NpcId.legionGeneralGroup then
        [ View.Icon.legion, Localized.text0 "history-npc-legion" ]

    else
        []


viewConquerorRow : HistoryRowConfig -> Dict NpcId (List String) -> ( Conqueror.Id, Conqueror.Encounter ) -> Html msg
viewConquerorRow { showDate } npcSays ( id, encounter ) =
    let
        says : List String
        says =
            Dict.get (Conqueror.npcFromId id) npcSays |> Maybe.withDefault []

        icon : Html msg
        icon =
            case id of
                Conqueror.Baran ->
                    View.Icon.baran

                Conqueror.Veritania ->
                    View.Icon.veritania

                Conqueror.AlHezmin ->
                    View.Icon.alHezmin

                Conqueror.Drox ->
                    View.Icon.drox

        body : List (Html msg)
        body =
            case encounter of
                Conqueror.Taunt n ->
                    [ icon
                    , Localized.text "history-conqueror-taunt"
                        [ Localized.string "conqueror" <| Conqueror.toString id
                        , Localized.int "taunt" n
                        ]
                    ]

                Conqueror.Fight ->
                    [ icon
                    , Localized.text "history-conqueror-fight"
                        [ Localized.string "conqueror" <| Conqueror.toString id
                        ]
                    ]
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
