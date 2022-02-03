module Page.History exposing (formatMaybeDuration, listRuns, view, viewDurationDelta, viewHistoryRun)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Mapwatch.MapRun.Sort as RunSort
import Mapwatch.MapRun.Trialmaster as Trialmaster
import Mapwatch.RawMapRun as RawMapRun
import Maybe.Extra
import Model exposing (Msg(..), OkModel)
import Page.NotFound
import Random exposing (Generator)
import Route
import Route.Feature as Feature
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
    if Mapwatch.isReady model.mapwatch && not (isValidPage (QueryDict.getInt Route.keys.page model.query |> Maybe.withDefault 0) model) then
        Page.NotFound.view model

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
            [ View.Util.viewSearch model.query
            , View.Util.viewDateSearch model.mapwatch.datamine.leagues model.query model.route
            , View.Util.viewGoalForm model.query
            , viewExactSearchResult model.mapwatch.datamine model.query
            ]
        , div []
            ([ span [ L.historyExport ] []
             , a [ Route.href model.query Route.HistoryTSV ] [ View.Icon.fas "table", text " ", span [ L.historyExportTsv ] [] ]
             ]
                ++ (if Feature.isActive Feature.GSheets model.query then
                        [ text " | "
                        , a [ Route.href model.query Route.GSheets ] [ View.Icon.fab "google-drive", text " ", span [ L.historyExportGoogle ] [] ]
                        ]

                    else
                        []
                   )
            )
        , viewStatsTable model.query model.tz model.now runs
        , viewHistoryTable runs model
        ]


viewExactSearchResult : Datamine -> QueryDict -> Html msg
viewExactSearchResult dm query =
    case Dict.get "q" query of
        Nothing ->
            div [] [ div [] [], View.Drops.empty ]

        Just q ->
            case Dict.get q dm.unindex.worldAreas |> Maybe.andThen (\id -> Dict.get id dm.worldAreasById) of
                Nothing ->
                    div [] [ div [] [], View.Drops.empty ]

                Just w ->
                    -- div [] [ text w.id ]
                    div []
                        [ div []
                            [ span [ class "zone" ]
                                [ View.Icon.mapOrBlank { isBlightedMap = False, isGrandHeist = Nothing } (Just w)
                                , text " "
                                , text q
                                ]
                            , span []
                                [ text " ("
                                , a [ target "_blank", href <| Datamine.wikiUrl dm w, L.timerMapWiki ] []
                                , text ")"
                                ]
                            ]
                        , View.Drops.view query dm w
                        ]


viewStatsTable : QueryDict -> Time.Zone -> Posix -> List MapRun -> Html msg
viewStatsTable query tz now runs =
    table [ class "history-stats" ]
        [ tbody []
            (case ( QueryDict.getPosix Route.keys.after query, QueryDict.getPosix Route.keys.before query ) of
                ( Nothing, Nothing ) ->
                    List.concat
                        [ viewStatsRows (span [ L.historySummaryToday ] []) (runs |> RunSort.filterToday tz now |> MapRun.aggregate)
                        , viewStatsRows (span [ L.historySummaryAlltime ] []) (runs |> MapRun.aggregate)
                        ]

                ( a, b ) ->
                    viewStatsRows (span [ L.historySummarySession ] []) (runs |> RunSort.filterBetween { before = b, after = a } |> MapRun.aggregate)
            )
        ]


viewStatsRows : Html msg -> MapRun.Aggregate -> List (Html msg)
viewStatsRows title runs =
    [ tr []
        [ th [ class "title" ] [ title ]
        , td ([ colspan 10, class "maps-completed" ] ++ L.historySummaryCount { n = toFloat runs.num }) []
        ]
    , tr []
        ([ td [] []
         , td [ L.historySummaryThMean ] []
         ]
            ++ viewDurationAggregate runs.mean
        )
    , tr []
        ([ td [] []
         , td [ L.historySummaryThTotal ] []
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
        [ firstLink [ View.Icon.fas "fast-backward", text " ", span [ L.historyPageFirst ] [] ]
        , prevLink [ View.Icon.fas "step-backward", text " ", span [ L.historyPagePrev ] [] ]
        , span [] [ span (L.historyPageCount { first = toFloat firstVisItem, last = toFloat lastVisItem, count = toFloat numItems }) [] ]
        , nextLink [ span [ L.historyPageNext ] [], text " ", View.Icon.fas "step-forward" ]
        , lastLink [ span [ L.historyPageLast ] [], text " ", View.Icon.fas "fast-forward" ]
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
        , tbody [] (pageRuns |> List.map (viewHistoryRun model { showDate = True, loadedAt = model.loadedAt } goalDuration) |> List.concat)
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
    { showDate : Bool
    , loadedAt : Posix
    }


type alias Duration =
    Int


viewHistoryRun : { m | query : QueryDict, tz : Time.Zone, mapwatch : { mm | datamine : Datamine } } -> HistoryRowConfig -> (MapRun -> Maybe Duration) -> MapRun -> List (Html msg)
viewHistoryRun ({ query, tz } as m) config goals r =
    viewHistoryMainRow m config (goals r) r
        :: List.concat
            [ viewAfkDurationRow query config r.duration.afk
            , r.sideAreas
                |> Dict.values
                |> List.map (viewHistorySideAreaRow query config)
            , r.conqueror
                |> Maybe.map (viewConquerorRow config r.npcSays)
                |> Maybe.Extra.toList
            , r.trialmaster
                |> List.map (viewTrialmasterRow config r.address)
            , r.rituals |> viewRitualRow query config
            , if r.isHeartOfTheGrove then
                [ viewHistoryNpcTextRow_ query config (Dict.get NpcId.oshabi r.npcSays |> Maybe.withDefault []) [ View.Icon.harvest, span [ L.historyHeartOfTheGrove ] [] ] ]

              else
                []
            , r.npcSays
                -- Ignore heist npcs who didn't use any skills
                |> Dict.filter (\npcId _ -> not (Set.member npcId NpcId.heistNpcs) || Set.member npcId r.heistNpcs)
                -- Don't show regular-harvest-Oshabi if it's heart of the grove
                |> Dict.filter (\npcId _ -> not (npcId == NpcId.oshabi && r.isHeartOfTheGrove))
                |> Dict.toList
                |> List.filterMap (viewHistoryNpcTextRow query config r.rootNpcs)
            ]


viewRitualRow : QueryDict -> HistoryRowConfig -> Int -> List (Html msg)
viewRitualRow query { showDate } count =
    if count > 0 then
        [ tr [ class "npctext-area" ]
            ((if showDate then
                [ td [ class "date" ] [] ]

              else
                []
             )
                ++ [ td [] []
                   , td [] []
                   , td [ colspan 7 ]
                        [ View.Icon.ritual
                        , span (L.historyRitual { n = toFloat count }) []
                        ]
                   , td [ class "side-dur" ]
                        []
                   , td [ class "portals" ] []
                   , td [ class "town-pct" ] []
                   ]
            )
        ]

    else
        []


viewAfkDurationRow : QueryDict -> HistoryRowConfig -> Int -> List (Html msg)
viewAfkDurationRow query { showDate } durationAfk =
    if Feature.isActive Feature.AFKDuration query && durationAfk > 0 then
        [ tr [ class "npctext-area" ]
            ((if showDate then
                [ td [ class "date" ] [] ]

              else
                []
             )
                ++ [ td [] []
                   , td [] []
                   , td [ colspan 7 ]
                        [ span [ L.historyAfkMode ] [] ]
                   , td [ class "side-dur" ]
                        [ text "-", viewDuration durationAfk ]
                   , td [ class "portals" ] []
                   , td [ class "town-pct" ] []
                   ]
            )
        ]

    else
        []


viewTrialmasterRow : HistoryRowConfig -> Address -> Trialmaster.State -> Html msg
viewTrialmasterRow { showDate } root state =
    let
        result : String
        result =
            case state.outcome of
                Trialmaster.Won _ ->
                    "victory"

                Trialmaster.Lost _ ->
                    "defeat"

                Trialmaster.Retreated _ ->
                    "retreat"

                Trialmaster.Abandoned ->
                    "incomplete"

        rounds =
            List.length state.mods

        body =
            if state.isBossFight then
                [ View.Icon.trialmaster
                , span (L.npcTrialmasterBoss { result = result }) []
                ]

            else
                [ View.Icon.trialmaster
                , span (L.npcTrialmaster { result = result, n = toFloat rounds }) []
                ]

        sideIcon =
            if root == state.address then
                []

            else
                [ span [ L.historyNpcSideArea ] [ View.Icon.zana ] ]
    in
    tr [ class "npctext-area" ]
        ((if showDate then
            [ td [ class "date" ] [] ]

          else
            []
         )
            ++ [ td [] []
               , td [] []
               , td [ colspan 7, title <| String.join "\n\n" state.says ]
                    [ div [] <| sideIcon ++ body
                    , div [] (state.mods |> List.map viewTrialmasterMod)
                    ]
               , td [ class "side-dur" ]
                    (state.outcome
                        |> Trialmaster.duration
                        |> Maybe.map (viewDuration >> List.singleton)
                        |> Maybe.withDefault []
                    )
               , td [ class "portals" ] []
               , td [ class "town-pct" ] []
               ]
        )


viewTrialmasterMod : Result String Datamine.UltimatumModifier -> Html msg
viewTrialmasterMod mmod =
    case mmod of
        Err npcTextId ->
            code [ style "background-color" "red" ] [ text npcTextId ]

        Ok mod ->
            img
                [ class "trialmaster-mod"
                , title <|
                    mod.name
                        ++ " ("
                        ++ mod.id
                        ++ ")"
                        ++ "\n\n"
                        ++ mod.description
                , src <| "https://web.poecdn.com/image/" ++ String.replace ".dds" "" mod.icon ++ ".png?scale=1"
                ]
                []


viewDurationAggregate : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
viewDurationAggregate a =
    [ td [ class "dur total-dur" ] [ viewDuration a.duration.all ] ]
        ++ viewDurationTail a


viewRunDurations : Maybe Duration -> MapRun -> List (Html msg)
viewRunDurations goal run =
    [ td [ class "dur total-dur" ]
        [ if run.isAbandoned then
            span
                [ class "abandoned-run-duration"
                , L.historyRunAbandoned
                ]
                []

          else
            viewDuration run.duration.all
        ]
    , td [ class "dur delta-dur" ] [ viewDurationDelta (Just run.duration.all) goal ]
    ]
        ++ viewDurationTail { portals = toFloat run.portals, duration = run.duration }


viewDurationTail : { a | portals : Float, duration : MapRun.Durations } -> List (Html msg)
viewDurationTail { portals, duration } =
    [ td [ class "dur" ] [ text " = " ]
    , td [ class "dur" ] [ text " ", span (L.historyDurMap { dur = View.Home.formatDuration duration.mainMap }) [], text " " ]
    , td [ class "dur" ] [ text " + " ]
    , td [ class "dur" ] [ text " ", span (L.historyDurTown { dur = View.Home.formatDuration duration.town }) [], text " " ]
    ]
        ++ (if duration.sides > 0 then
                [ td [ class "dur" ] [ text " + " ]
                , td [ class "dur" ] [ text " ", span (L.historyDurSides { dur = View.Home.formatDuration duration.sides }) [], text " " ]
                ]

            else
                [ td [ class "dur" ] [], td [ class "dur" ] [] ]
           )
        ++ [ td [ class "portals" ] [ span (L.historyDurPortals { n = portals }) [] ]
           , td [ class "town-pct" ]
                [ span (L.historyDurTownPct { pct = toFloat <| clamp 0 100 <| floor <| 100 * (toFloat duration.town / Basics.max 1 (toFloat duration.all)) }) [] ]
           ]


viewHistoryMainRow : { m | query : QueryDict, tz : Time.Zone, mapwatch : { mm | datamine : Datamine } } -> HistoryRowConfig -> Maybe Duration -> MapRun -> Html msg
viewHistoryMainRow ({ tz, query } as m) { showDate } goal r =
    tr [ class "main-area" ]
        ((if showDate then
            if Feature.isActive Feature.LogSlice query then
                [ td [ class "date" ] [ a [ Route.href query <| Route.LogSlice r.positionStart r.positionEnd ] [ View.Home.viewDate tz r.updatedAt ] ] ]

            else
                [ td [ class "date" ] [ View.Home.viewDate tz r.updatedAt ] ]

          else
            []
         )
            ++ [ td [ class "zone" ] [ View.Home.viewRun query r ]
               , td (L.historySearchable { searchable = RunSort.searchString m.mapwatch.datamine r })
                    [ View.Home.viewRegion query r.address.worldArea ]
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


viewHistoryNpcTextRow : QueryDict -> HistoryRowConfig -> Set NpcId -> ( NpcId, List String ) -> Maybe (Html msg)
viewHistoryNpcTextRow query config rootNpcs ( npcId, texts ) =
    case viewNpcText query config.loadedAt npcId of
        [] ->
            Nothing

        body ->
            if Set.member npcId NpcId.heistNpcs && not (Feature.isActive Feature.HeistNpcs query) then
                Nothing

            else
                let
                    sideIcon =
                        if Set.member npcId rootNpcs || body == [] then
                            []

                        else
                            [ span [ L.historyNpcSideArea ] [ View.Icon.zana ] ]
                in
                Just <| viewHistoryNpcTextRow_ query config texts <| sideIcon ++ body


viewHistoryNpcTextRow_ : QueryDict -> HistoryRowConfig -> List String -> List (Html msg) -> Html msg
viewHistoryNpcTextRow_ query { showDate, loadedAt } texts body =
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


viewNpcText : QueryDict -> Posix -> String -> List (Html msg)
viewNpcText query loadedAt npcId =
    let
        t attr =
            span [ attr ] []
    in
    if npcId == NpcId.einhar then
        [ View.Icon.einhar, t L.npcEinhar ]

    else if npcId == NpcId.alva then
        [ View.Icon.alva, t L.npcAlva ]

    else if npcId == NpcId.niko then
        [ View.Icon.niko, t L.npcNiko ]

    else if npcId == NpcId.betrayalGroup then
        -- else if npcId == NpcId.jun then
        [ View.Icon.jun, t L.npcJun ]

    else if npcId == NpcId.cassia then
        [ View.Icon.cassia, t L.npcCassia ]
        -- Don't show Tane during Metamorph league
        -- Actually, his voicing is so inconsistent that we can't show him after metamorph league either!
        -- else if npcId == NpcId.tane then
        -- [ View.Icon.tane, text "Tane Octavius" ]
        -- Don't show conquerors, they have their own special function

    else if npcId == NpcId.delirium then
        [ View.Icon.delirium, t L.npcDelirium ]

    else if npcId == NpcId.legionGeneralGroup then
        [ View.Icon.legion, t L.npcLegionGeneral ]

    else if npcId == NpcId.karst then
        [ View.Icon.karst, t L.npcKarst ]

    else if npcId == NpcId.niles then
        [ View.Icon.niles, t L.npcNiles ]

    else if npcId == NpcId.huck then
        [ View.Icon.huck, t L.npcHuck ]

    else if npcId == NpcId.tibbs then
        [ View.Icon.tibbs, t L.npcTibbs ]

    else if npcId == NpcId.nenet then
        [ View.Icon.nenet, t L.npcNenet ]

    else if npcId == NpcId.vinderi then
        [ View.Icon.vinderi, t L.npcVinderi ]

    else if npcId == NpcId.tortilla then
        [ View.Icon.tortilla, span (tortillaName loadedAt) [] ]

    else if npcId == NpcId.gianna then
        [ View.Icon.gianna, t L.npcGianna ]

    else if npcId == NpcId.isla then
        [ View.Icon.isla, t L.npcIsla ]

    else if npcId == NpcId.envoy then
        [ View.Icon.envoy, t L.npcEnvoy ]

    else if npcId == NpcId.maven then
        [ View.Icon.maven, t L.npcMaven ]

    else if npcId == NpcId.oshabi then
        [ View.Icon.harvest, t L.npcOshabi ]

    else if npcId == NpcId.sirus then
        [ View.Icon.sirus, t L.npcSirus ]

    else if npcId == NpcId.gwennen then
        [ View.Icon.gwennen, t L.npcGwennen ]

    else if npcId == NpcId.tujen then
        [ View.Icon.tujen, t L.npcTujen ]

    else if npcId == NpcId.rog then
        [ View.Icon.rog, t L.npcRog ]

    else if npcId == NpcId.dannig then
        [ View.Icon.dannig, t L.npcDannig ]

    else
        []


tortillaName : Posix -> List (H.Attribute msg)
tortillaName loadedAt =
    -- https://www.reddit.com/r/pathofexile/comments/iwbvt2/got_it_good/
    -- memes are serious business
    let
        gen : Generator (Generator (List (H.Attribute msg)))
        gen =
            Random.weighted
                ( 65, Random.constant [ L.npcTullina ] )
                [ ( 35
                  , Random.uniform
                        "Tutu"
                        [ "Tina"
                        , "Teeny"
                        , "Thimblina"
                        , "Tulololina"
                        , "Tumblrina"
                        , "Tortilla"
                        , "Lee"
                        , "Tukohama"
                        , "Leelee"
                        , "Tony"
                        ]
                        |> Random.map (\n -> L.npcTortilla { name = n })
                  )
                ]
    in
    Random.initialSeed (Time.posixToMillis loadedAt)
        |> Random.step gen
        |> (\( gen1, seed ) -> Random.step gen1 seed)
        |> Tuple.first


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
                    [ View.Icon.baran, span [ L.npcBaran ] [] ]

                Conqueror.Veritania ->
                    [ View.Icon.veritania, span [ L.npcVeritania ] [] ]

                Conqueror.AlHezmin ->
                    [ View.Icon.alHezmin, span [ L.npcAlhezmin ] [] ]

                Conqueror.Drox ->
                    [ View.Icon.drox, span [ L.npcDrox ] [] ]

        body : List (Html msg)
        body =
            case encounter of
                Conqueror.Taunt n ->
                    label ++ [ span (L.npcConquerorTaunt { n = toFloat n }) [] ]

                Conqueror.Fight ->
                    label ++ [ span [ L.npcConquerorFight ] [] ]
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
