module Page.Encounters exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.EncounterTally as EncounterTally exposing (EncounterTally)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Model as Model exposing (Msg(..), OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Time exposing (Posix)
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

        Mapwatch.Ready p ->
            div []
                [ viewMain model
                , View.Home.viewProgress p
                ]


applySearch : Datamine -> Maybe String -> List MapRun -> List MapRun
applySearch dm mq =
    case mq of
        Nothing ->
            identity

        Just q ->
            RunSort.search dm q


viewMain : OkModel -> Html Msg
viewMain model =
    let
        before =
            QueryDict.getPosix Route.keys.before model.query

        after =
            QueryDict.getPosix Route.keys.after model.query

        search =
            Dict.get Route.keys.search model.query

        runs : List MapRun
        runs =
            model.mapwatch.runs
                |> List.filter (\r -> not r.isAbandoned)
                |> applySearch model.mapwatch.datamine search
                |> RunSort.filterBetween { before = before, after = after }
    in
    div []
        [ View.Util.viewSearch model.query
        , View.Util.viewDateSearch model.mapwatch.datamine.leagues model.query model.route
        , div [] <| viewMainDisclaimer
        , div [] <| viewEncounterTally model.query <| EncounterTally.fromMapRuns runs
        ]


viewMainDisclaimer =
    [ div [ L.encountersDesc ]
        [ h4 [] [ u [ L.encountersDescHeader ] [] ]
        , p [ L.encountersDesc1 ] []
        , p [ L.encountersDesc2 ] []
        ]
    ]


viewEncounterTally : QueryDict -> EncounterTally -> List (Html msg)
viewEncounterTally query tally =
    let
        encs =
            listEncounterTally query tally
    in
    [ viewEncounterTally_
        [ span [ L.encountersTableMapName ] [] ]
        [ span (L.encountersTableMapRate { n = toFloat tally.normalMaps }) [] ]
        query
        encs.maps
    , viewEncounterTally_
        [ span [ L.encountersTableEndgameName ] [] ]
        [ span (L.encountersTableEndgameRate { n = toFloat tally.count }) [] ]
        query
        encs.areas
    , if tally.trialmaster > 0 then
        viewEncounterTally_
            [ span [ L.encountersTableTrialmasterName ] [] ]
            [ span (L.encountersTableTrialmasterRate { n = toFloat tally.trialmaster }) [] ]
            query
            encs.trialmasters

      else
        []
    , if tally.trialmasterBossRolls > 0 then
        viewEncounterTally_
            [ span [ L.encountersTableTrialmasterWinsName ] [] ]
            [ span (L.encountersTableTrialmasterWinsRate { n = toFloat tally.trialmaster }) [] ]
            query
            encs.trialmasterBossRolls

      else
        []
    ]
        |> List.concat


viewEncounterTally_ : List (Html msg) -> List (Html msg) -> QueryDict -> List (TallyEntry msg) -> List (Html msg)
viewEncounterTally_ header1 header2 query entries =
    if entries == [] then
        []

    else
        [ table [ class "encounters" ]
            [ thead []
                [ th [ style "text-align" "right" ] header1
                , th [] []
                , th [] header2
                ]
            , tbody []
                (entries
                    |> List.map
                        (\row ->
                            tr []
                                [ td [ style "text-align" "right" ]
                                    (case row.search of
                                        Nothing ->
                                            row.label

                                        Just search ->
                                            let
                                                q =
                                                    query |> Dict.insert "q" search
                                            in
                                            [ a [ Route.href q Route.Encounters ] row.label ]
                                    )
                                , td (L.encountersCount { n = toFloat row.count }) []
                                , td [] <|
                                    if isInfinite row.pct then
                                        [ text "-" ]

                                    else
                                        [ row.pct * 100 |> String.fromFloat |> String.left 5 |> text, text "%" ]
                                ]
                                :: (if row.disclaimer == [] then
                                        []

                                    else
                                        [ tr [] [ td [ colspan 3 ] row.disclaimer ] ]
                                   )
                        )
                    |> List.concat
                )
            ]
        ]


type alias TallyEntry msg =
    { label : List (Html msg)
    , count : Int
    , pct : Float
    , search : Maybe String
    , disclaimer : List (Html msg)
    }


type alias EncounterTables msg =
    { maps : List (TallyEntry msg)
    , areas : List (TallyEntry msg)
    , trialmasters : List (TallyEntry msg)
    , trialmasterBossRolls : List (TallyEntry msg)
    }


listEncounterTally : QueryDict -> EncounterTally -> EncounterTables msg
listEncounterTally query tally =
    let
        entry : Int -> String -> List (Html msg) -> TallyEntry msg
        entry count search label =
            discEntry count tally.normalMaps search label []

        nonMapEntry : Int -> String -> List (Html msg) -> TallyEntry msg
        nonMapEntry count search label =
            discEntry count tally.count search label []

        trialmasterEntry : Int -> String -> List (Html msg) -> TallyEntry msg
        trialmasterEntry count search label =
            discEntry count tally.trialmaster search label []

        discEntry : Int -> Int -> String -> List (Html msg) -> List (Html msg) -> TallyEntry msg
        discEntry count max search label disc =
            { label = label
            , search =
                if search == "" then
                    Nothing

                else
                    Just search
            , count = count
            , pct = toFloat count / toFloat max
            , disclaimer = disc
            }

        t attr =
            span [ attr ] []
    in
    { maps =
        [ entry tally.abyssalDepths "side:abyssal depths" [ View.Icon.abyss, t L.encounterAbyssal ]
        , entry tally.vaalAreas "vaal-side:" [ View.Icon.vaal, t L.encounterVaal ]
        , entry tally.labTrialsTotal "lab-trial-side:" [ View.Icon.labTrial, span (L.encounterTrial { n = toFloat <| List.length tally.labTrials }) [] ]
        , entry tally.conquerors "conqueror:" [ View.Icon.sirus, t L.encounterConquerors ]
        , entry tally.zana "npc:zana" [ View.Icon.zana, t L.encounterZana ]
        , entry tally.einhar "npc:einhar" [ View.Icon.einhar, t L.encounterEinhar ]
        , entry tally.alva "npc:alva" [ View.Icon.alva, t L.encounterAlva ]
        , entry tally.niko "npc:niko" [ View.Icon.niko, t L.encounterNiko ]
        , entry tally.jun "npc:jun" [ View.Icon.jun, t L.encounterJun ]
        , entry tally.cassia "npc:cassia" [ View.Icon.cassia, t L.encounterCassia ]
        , entry tally.delirium "npc:strange voice" [ View.Icon.delirium, t L.encounterDelirium ]
        , discEntry tally.oshabi
            tally.normalMaps
            "npc:oshabi"
            [ View.Icon.harvest, t L.encounterOshabi ]
            -- https://github.com/mapwatch/mapwatch/issues/183
            [ span [ L.encounterOshabiWarn ]
                [ a [ L.name_ "link", target "_blank", href "https://github.com/mapwatch/mapwatch#my-harvest-encounter-rate-seems-low" ] []
                ]
            ]
        , entry tally.heartOfTheGrove "heartOfTheGrove" [ View.Icon.harvest, t L.encounterHeartGrove ]
        , entry tally.envoy "npc:envoy" [ View.Icon.envoy, t L.encounterEnvoy ]
        , entry tally.sirusInvasions "npc:sirus" [ View.Icon.sirus, t L.encounterSirusInvasions ]
        , entry tally.maven "npc:the maven" [ View.Icon.maven, t L.encounterMaven ]
        , entry tally.trialmaster "npc:the trialmaster" [ View.Icon.trialmaster, t L.encounterTrialmaster ]
        , entry tally.gwennen "npc:gwennen" [ View.Icon.gwennen, t L.encounterGwennen ]
        , entry tally.tujen "npc:tujen" [ View.Icon.tujen, t L.encounterTujen ]
        , entry tally.rog "npc:rog" [ View.Icon.rog, t L.encounterRog ]
        , entry tally.dannig "npc:dannig" [ View.Icon.dannig, t L.encounterDannig ]
        , entry tally.ritual "ritual:" [ View.Icon.ritual, t L.encounterRitual ]
        ]
            |> List.filter (\r -> r.count > 0)
            |> List.sortBy .count
            |> List.reverse
    , areas =
        [ nonMapEntry tally.grandHeists "grand-heist:" [ View.Icon.grandHeistGeneric, t L.encounterGrandHeist ]
        , nonMapEntry tally.heistContracts "heist-contract:" [ View.Icon.heistContractGeneric, t L.encounterHeistContract ]
        , nonMapEntry tally.normalMaps "normal-map:" [ View.Icon.zana, t L.encounterNormalMaps ]
        , nonMapEntry tally.labyrinths "The Labyrinth" [ View.Icon.labTrial, t L.encounterLab ]
        , nonMapEntry tally.uniqueMaps "unique-map:" [ View.Icon.uniqueMap, t L.encounterUniqueMaps ]
        , nonMapEntry tally.blightedMaps "blighted" [ View.Icon.blightedMap, t L.encounterBlightedMaps ]
        , nonMapEntry tally.mavenCrucibles "id:MavenHub" [ View.Icon.maven, t L.encounterMavenHub ]
        , nonMapEntry tally.sirusFights "id:AtlasExilesBoss5" [ View.Icon.sirus, t L.encounterSirus ]
        ]
            |> List.filter (\r -> r.count > 0)
            |> List.sortBy .count
            |> List.reverse
    , trialmasters =
        [ trialmasterEntry tally.trialmasterWon "trialmaster-won" [ View.Icon.trialmaster, t L.encounterTrialmastersWon ]
        , trialmasterEntry tally.trialmasterLost "trialmaster-lost" [ View.Icon.trialmaster, t L.encounterTrialmastersLost ]
        , trialmasterEntry tally.trialmasterRetreated "trialmaster-retreated" [ View.Icon.trialmaster, t L.encounterTrialmastersRetreated ]
        , trialmasterEntry tally.trialmasterAbandoned "trialmaster-abandoned" [ View.Icon.trialmaster, t L.encounterTrialmastersIncomplete ]
        ]
    , trialmasterBossRolls =
        [ discEntry tally.trialmasterBosses
            tally.trialmasterBossRolls
            "trialmaster-boss"
            [ View.Icon.trialmaster, t L.encounterTrialmasterBoss ]
            [ span [ L.encounterTrialmasterBossWarn ]
                [ a [ L.name_ "link", target "_blank", href "https://old.reddit.com/r/pathofexile/comments/n4ahe0/3141b_patch_notes/gwuktc9/" ] []
                ]
            ]
        ]
    }
