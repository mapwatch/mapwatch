module Page.Bosses exposing (view, viewBossTally)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.BossEntry as BossEntry exposing (BossEntry, Progress)
import Mapwatch.BossShare as BossShare
import Mapwatch.BossTally as BossTally exposing (BossTally)
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
import View.Icon as Icon
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

        tally : BossTally
        tally =
            runs |> List.filterMap .bossTally |> BossTally.aggregate
    in
    div []
        [ View.Util.viewSearch model.query
        , View.Util.viewDateSearch model.mapwatch.datamine.leagues model.query model.route
        , div []
            [ a
                [ class "button"
                , target "_blank"
                , Route.href Dict.empty <| Route.SharedBosses <| BossShare.base64Encode <| BossShare.create tally
                ]
                [ Icon.fas "share-nodes", text " ", span [ L.bossesShareButton ] [] ]
            ]
        , div [] <| viewBossTally model.query tally
        ]


viewBossTally : QueryDict -> BossTally -> List (Html msg)
viewBossTally query tally =
    [ table []
        [ tally |> BossTally.groupAll |> viewBossEntries query L.bossesGroupAll |> tr []

        -- shaper guardians
        , tally |> BossTally.groupShaperGuardians |> viewBossEntries query L.bossesGroupShaperGuardians |> tr []
        , tally.shaperChimera |> viewBossEntry query L.bossesShaperChimera "id:MapWorldsChimera" |> tr []
        , tally.shaperHydra |> viewBossEntry query L.bossesShaperHydra "id:MapWorldsHydra" |> tr []
        , tally.shaperMinotaur |> viewBossEntry query L.bossesShaperMinotaur "id:MapWorldsMinotaur" |> tr []
        , tally.shaperPhoenix |> viewBossEntry query L.bossesShaperPhoenix "id:MapWorldsPhoenix" |> tr []

        -- lesser conquerors
        , tally |> BossTally.groupConquerors |> viewBossEntries query L.bossesGroupConquerors |> tr []
        , tally.baran |> viewBossEntry query L.bossesBaran "conqueror:fight:baran" |> tr []
        , tally.veritania |> viewBossEntry query L.bossesVeritania "conqueror:fight:veritania" |> tr []
        , tally.alhezmin |> viewBossEntry query L.bossesAlhezmin "conqueror:fight:alHezmin" |> tr []
        , tally.drox |> viewBossEntry query L.bossesDrox "conqueror:fight:drox" |> tr []

        -- shaper, elder
        , tally |> BossTally.groupLesserEldritch |> viewBossEntries query L.bossesGroupLesserEldritch |> tr []

        -- , tally.atziri.standard |> viewBossSighting query L.bossesAtziri "id:MapAtziri1" |> tr []
        , tally.elder |> viewBossEntry query L.bossesElder "id:MapWorldsElderArena" |> tr []
        , tally.hunger |> viewBossEntry query L.bossesHunger "id:MapWorldsPrimordialBoss1" |> tr []
        , tally.blackstar |> viewBossEntry query L.bossesBlackstar "id:MapWorldsPrimordialBoss2" |> tr []

        -- pinnacles
        , tally |> BossTally.groupPinnacle |> viewBossEntries query L.bossesGroupPinnacle |> tr []
        , tally.exarch.standard |> viewBossEntry query L.bossesExarch "id:MapWorldsPrimordialBoss3" |> tr []
        , tally.eater.standard |> viewBossEntry query L.bossesEater "id:MapWorldsPrimordialBoss4" |> tr []
        , tally.venarius.standard |> viewBossEntry query L.bossesVenarius "id:Synthesis_MapBoss" |> tr []
        , tally.sirus.standard |> viewBossEntry query L.bossesSirus "id:AtlasExilesBoss5" |> tr []
        , tally.maven.standard |> viewBossEntry query L.bossesMaven "id:MavenBoss" |> tr []
        , tally.uberelder.standard |> viewBossEntry query L.bossesUberElder "id:MapWorldsElderArenaUber" |> tr []
        , tally.shaper.standard |> viewBossEntry query L.bossesShaper "id:MapWorldsShapersRealm" |> tr []

        -- uber pinnacles (and atziri)
        -- TODO: fix uber vs non-uber searches
        , tally |> BossTally.groupUber |> viewBossEntries query L.bossesGroupUber |> tr []
        , tally.exarch.uber |> viewBossEntry query L.bossesUberExarch "id:MapWorldsPrimordialBoss3" |> tr []
        , tally.eater.uber |> viewBossEntry query L.bossesUberEater "id:MapWorldsPrimordialBoss4" |> tr []
        , tally.venarius.uber |> viewBossEntry query L.bossesUberVenarius "id:Synthesis_MapBoss" |> tr []
        , tally.sirus.uber |> viewBossEntry query L.bossesUberSirus "id:AtlasExilesBoss5" |> tr []
        , tally.maven.uber |> viewBossEntry query L.bossesUberMaven "id:MavenBoss" |> tr []
        , tally.uberelder.uber |> viewBossEntry query L.bossesUberUberElder "id:MapWorldsElderArenaUber" |> tr []
        , tally.shaper.uber |> viewBossEntry query L.bossesUberShaper "id:MapWorldsShapersRealm" |> tr []
        , tally.atziri.uber |> viewBossEntry query L.bossesUberAtziri "id:MapAtziri2" |> tr []
        ]
    ]


viewBossEntries : QueryDict -> H.Attribute msg -> List BossEntry -> List (Html msg)
viewBossEntries query label entries =
    -- TODO: mergeEntries has bad behavior here! it ORs, but we want AND here.
    -- viewBossProgressEntry query label search (BossTally.entriesProgress entries) (BossTally.mergeEntries entries)
    let
        progress =
            BossEntry.progressList entries
    in
    [ td [ style "text-align" "right" ] [ span [ label ] [] ]
    , td [ colspan 4 ] [ viewProgress progress ]
    ]


viewBossEntry : QueryDict -> H.Attribute msg -> String -> BossEntry -> List (Html msg)
viewBossEntry query label search entry =
    let
        progress =
            BossEntry.progress entry

        href =
            Route.href (query |> Dict.insert "q" search) Route.Encounters
    in
    [ td [ style "text-align" "right" ] [ a [ href, label ] [] ]

    -- , td [ ] [ viewProgress progress ]
    , td [ style "text-align" "center" ] [ entry |> BossEntry.isVisited |> viewBool, span [ L.bossesHeaderVisited ] [] ]
    , td [ style "text-align" "center" ] [ entry |> BossEntry.isVictory |> viewBool, span [ L.bossesHeaderVictory ] [] ]
    , td [ style "text-align" "center" ] [ entry |> BossEntry.isDeathless |> viewBool, span [ L.bossesHeaderDeathless ] [] ]
    , td [ style "text-align" "center" ] [ entry |> BossEntry.isLogoutless |> viewBool, span [ L.bossesHeaderLogoutless ] [] ]

    -- , td [ style "text-align" "center" ] [ text "?" ]
    -- , td [] [ text <| String.fromInt entry.runs ]
    --, td [ style "text-align" "center" ]
    --    [ text <|
    --        if entry.completed > 0 then
    --            String.fromInt entry.completed
    --        else
    --            ""
    --    ]
    -- , td [] [ text <| String.fromInt <| Maybe.withDefault 0 entry.minDeaths ]
    -- , td [] [ text <| String.fromInt entry.totalDeaths ]
    ]


viewProgress : Progress -> Html msg
viewProgress p =
    H.meter
        [ A.max <| String.fromInt p.possible
        , A.value <| String.fromInt p.completed
        , A.title <| String.fromInt p.completed ++ "/" ++ String.fromInt p.possible
        , A.style "width" "100%"
        ]
        []


viewBool : Bool -> Html msg
viewBool b =
    if b then
        span [ style "color" "green" ] [ text " ✔ " ]

    else
        span [ style "color" "red" ] [ text " ✖ " ]
