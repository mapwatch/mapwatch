module Page.Bosses exposing (view, viewContent)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.BossEntry as BossEntry exposing (BossEntry, Progress)
import Mapwatch.BossMark as BossMark exposing (BossId(..))
import Mapwatch.BossShare as BossShare
import Mapwatch.BossTally as BossTally exposing (BossTally, Group(..))
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.EncounterTally as EncounterTally exposing (EncounterTally)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Maybe.Extra
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
            (a
                [ class "button"
                , target "_blank"
                , Route.href Dict.empty <| Route.SharedBosses <| BossShare.base64Encode <| BossShare.create tally
                ]
                [ Icon.fas "share-nodes", text " ", span [ L.bossesShareButton ] [] ]
                :: viewContent model.query tally
            )
        ]


viewContent : QueryDict -> BossTally -> List (Html msg)
viewContent query tally =
    [ div [] <| viewAchievementsSummary query tally
    , div [] <| viewDetailedTally query tally
    , div [] <| viewBossTally query tally
    ]


viewAchievementsSummary : QueryDict -> BossTally -> List (Html msg)
viewAchievementsSummary query tally =
    [ div [ class "achievements-summary" ]
        ((tally |> BossTally.groupProgress All |> viewAchievementsSummaryEntry (groupLabel All) |> div [ class "total" ])
            :: (BossTally.groups
                    |> List.map
                        (\g ->
                            tally
                                |> BossTally.groupProgress g
                                |> viewAchievementsSummaryEntry (groupLabel g)
                                |> div [ class "entry" ]
                        )
               )
            ++ ([ ( BossEntry.progressVisited, L.bossesHeaderVisited )
                , ( BossEntry.progressVictory, L.bossesHeaderVictory )
                , ( BossEntry.progressDeathless, L.bossesHeaderDeathless )
                , ( BossEntry.progressLogoutless, L.bossesHeaderLogoutless )
                ]
                    |> List.map
                        (\( progressFn, label ) ->
                            tally
                                |> BossTally.toEntries
                                |> List.map Tuple.second
                                |> progressFn
                                |> viewAchievementsSummaryEntry label
                                |> div [ class "entry" ]
                        )
               )
        )
    ]


viewAchievementsSummaryEntry : H.Attribute msg -> Progress -> List (Html msg)
viewAchievementsSummaryEntry label progress =
    [ span [ class "label", label ] []
    , span [ class "percent" ]
        [ if progress.percent >= 1 then
            viewBool True

          else
            progress.percent |> formatPercent |> text
        ]
    , progress |> viewProgress
    ]


viewDetailedTally : QueryDict -> BossTally -> List (Html msg)
viewDetailedTally query tally =
    []


viewBossTally : QueryDict -> BossTally -> List (Html msg)
viewBossTally query tally =
    [ table []
        ((tally
            |> BossTally.toEntries
            |> List.map Tuple.second
            |> viewBossGroup query All
            |> tr []
         )
            :: (tally
                    |> BossTally.toEntryGroups
                    |> List.concatMap
                        (\( g, es ) ->
                            (es |> List.map Tuple.second |> viewBossGroup query g |> tr [])
                                :: (es |> List.map (\( id, e ) -> e |> viewBossEntry query id |> tr []))
                        )
               )
        )
    ]


viewBossGroup : QueryDict -> Group -> List BossEntry -> List (Html msg)
viewBossGroup query id entries =
    let
        kills : Int
        kills =
            entries |> List.filterMap BossEntry.victoryData |> List.map .count |> List.sum

        progress =
            entries |> BossEntry.progressList
    in
    [ td [ style "text-align" "right" ] [ span [ groupLabel id ] [] ]
    , td [ colspan 4 ] [ viewProgress progress ]
    , td [] [ span ({ n = kills |> toFloat } |> L.bossesKills) [] ]
    ]


viewBossEntry : QueryDict -> BossId -> BossEntry -> List (Html msg)
viewBossEntry query id entry =
    let
        progress =
            BossEntry.progress entry

        kills : Int
        kills =
            entry |> BossEntry.victoryData |> Maybe.Extra.unwrap 0 .count

        search =
            "boss:" ++ BossMark.searchableId id

        href =
            Route.href (query |> Dict.insert "q" search) Route.History
    in
    [ td [ style "text-align" "right" ] [ a [ href, bossLabel id ] [] ]
    , td [] [ entry |> BossEntry.isVisited |> viewBool, span [ L.bossesHeaderVisited ] [] ]
    , td [] [ entry |> BossEntry.isVictory |> viewBool, span [ L.bossesHeaderVictory ] [] ]
    , td [] [ entry |> BossEntry.isDeathless |> viewBool, span [ L.bossesHeaderDeathless ] [] ]
    , td [] [ entry |> BossEntry.isLogoutless |> viewBool, span [ L.bossesHeaderLogoutless ] [] ]
    , td [] [ span ({ n = kills |> toFloat } |> L.bossesKills) [] ]
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


formatPercent : Float -> String
formatPercent f =
    (f * 100 |> floor |> String.fromInt) ++ "%"


groupLabel : Group -> H.Attribute msg
groupLabel id =
    case id of
        All ->
            L.bossesGroupAll

        Ubers ->
            L.bossesGroupUbers

        Pinnacles ->
            L.bossesGroupPinnacles

        Conquerors ->
            L.bossesGroupConquerors

        LesserEldritches ->
            L.bossesGroupLesserEldritches

        Breachlords ->
            L.bossesGroupBreachlords

        ShaperGuardians ->
            L.bossesGroupShaperGuardians


bossLabel : BossId -> H.Attribute msg
bossLabel id =
    case id of
        Atziri isUber ->
            valueIf L.bossesUberAtziri L.bossesAtziri isUber

        UberElder isUber ->
            valueIf L.bossesUberUberElder L.bossesUberElder isUber

        Shaper isUber ->
            valueIf L.bossesUberShaper L.bossesShaper isUber

        Venarius isUber ->
            valueIf L.bossesUberVenarius L.bossesVenarius isUber

        Maven isUber ->
            valueIf L.bossesUberMaven L.bossesMaven isUber

        Sirus isUber ->
            valueIf L.bossesUberSirus L.bossesSirus isUber

        Exarch isUber ->
            valueIf L.bossesUberExarch L.bossesExarch isUber

        Eater isUber ->
            valueIf L.bossesUberEater L.bossesEater isUber

        BlackStar ->
            L.bossesBlackstar

        Hunger ->
            L.bossesHunger

        Elder ->
            L.bossesElder

        Baran ->
            L.bossesBaran

        Veritania ->
            L.bossesVeritania

        AlHezmin ->
            L.bossesAlhezmin

        Drox ->
            L.bossesDrox

        ShaperMinotaur ->
            L.bossesShaperMinotaur

        ShaperChimera ->
            L.bossesShaperChimera

        ShaperPhoenix ->
            L.bossesShaperPhoenix

        ShaperHydra ->
            L.bossesShaperHydra

        BreachXoph ->
            L.bossesBreachXoph

        BreachTul ->
            L.bossesBreachTul

        BreachEsh ->
            L.bossesBreachEsh

        BreachUul ->
            L.bossesBreachUul

        BreachChayula ->
            L.bossesBreachChayula

        Mastermind ->
            L.bossesMastermind


valueIf : a -> a -> Bool -> a
valueIf t f pred =
    if pred then
        t

    else
        f
