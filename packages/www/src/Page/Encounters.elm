module Page.Encounters exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.EncounterTally as EncounterTally exposing (EncounterTally)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Page.History
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
        [ View.Util.viewSearch [ placeholder "map name" ] model.query
        , View.Util.viewDateSearch model.mapwatch.datamine.leagues model.query model.route
        , div [] <| viewMainDisclaimer
        , div [] <| viewEncounterTally model.query <| EncounterTally.fromMapRuns runs
        ]


viewMainDisclaimer =
    [ div [ title "I try not to screw up these numbers or otherwise mislead people, but if it keeps happening I'm going to just delete this damn page" ]
        [ h4 [] [ u [] [ text "Do not blindly trust Mapwatch" ] ]
        , p [] [ text "Sometimes Mapwatch is misleading or just plain wrong. Before using this page as evidence for your Angry Reddit Thread about spawn rates, you should double-check Mapwatch's numbers, and think carefully about your conclusions." ]
        , p [] [ text "It is ", i [] [ text "very unlikely" ], text " that you've found a Path of Exile bug." ]
        ]
    ]


viewEncounterTally : QueryDict -> EncounterTally -> List (Html msg)
viewEncounterTally query tally =
    let
        ( mapEncs, nonMapEncs ) =
            listEncounterTally query tally
    in
    [ viewEncounterTally_
        [ text "Map encounters" ]
        [ text "% of "
        , text <| String.fromInt tally.normalMaps
        , text " maps"
        ]
        query
        mapEncs
    , viewEncounterTally_
        [ text "Endgame area encounters" ]
        [ text "% of "
        , text <| String.fromInt tally.count
        , text " endgame areas"
        ]
        query
        nonMapEncs
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
                                , td [] [ text "×", text <| String.fromInt row.count ]
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


listEncounterTally : QueryDict -> EncounterTally -> ( List (TallyEntry msg), List (TallyEntry msg) )
listEncounterTally query tally =
    let
        entry : Int -> String -> List (Html msg) -> TallyEntry msg
        entry count search label =
            discEntry count tally.normalMaps search label []

        nonMapEntry : Int -> String -> List (Html msg) -> TallyEntry msg
        nonMapEntry count search label =
            discEntry count tally.count search label []

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
    in
    ( [ entry tally.abyssalDepths "side:abyssal depths" [ View.Icon.abyss, text "Abyssal Depths" ]
      , entry tally.vaalAreas "vaal-side:" [ View.Icon.vaal, text "Vaal side areas" ]
      , entry tally.labTrialsTotal "lab-trial-side:" [ View.Icon.labTrial, text "(", text <| String.fromInt <| List.length tally.labTrials, text "/6) Labyrinth Trials" ]
      , entry tally.conquerors "conqueror:" [ span [ title "excluding Sirus" ] [ View.Icon.sirus, text "Conqueror Fights" ] ]
      , entry tally.zana "npc:zana" [ View.Icon.zana, text "Zana" ]
      , entry tally.einhar "npc:einhar" [ View.Icon.einhar, text "Einhar" ]
      , entry tally.alva "npc:alva" [ View.Icon.alva, text "Alva" ]
      , entry tally.niko "npc:niko" [ View.Icon.niko, text "Niko" ]
      , entry tally.jun "npc:jun" [ View.Icon.jun, text "Jun" ]
      , entry tally.cassia "npc:cassia" [ View.Icon.cassia, text "Cassia" ]
      , entry tally.delirium "npc:strange voice" [ View.Icon.delirium, text "Delirium" ]
      , discEntry tally.oshabi
            tally.normalMaps
            "npc:oshabi"
            [ View.Icon.harvest, text "Oshabi", b [] [ text " * " ] ]
            -- https://github.com/mapwatch/mapwatch/issues/183
            [ text "* Beware: Mapwatch cannot accurately track Harvests. "
            , a [ target "_blank", href "https://github.com/mapwatch/mapwatch#my-harvest-encounter-rate-seems-low" ]
                [ text "Your true Harvest rate is higher." ]
            ]
      , entry tally.heartOfTheGrove "heartOfTheGrove" [ View.Icon.harvest, text "Heart of the Grove" ]
      , entry tally.envoy "npc:envoy" [ View.Icon.envoy, text "The Envoy" ]
      , entry tally.sirusInvasions "npc:sirus" [ View.Icon.sirus, text "Sirus Invasions" ]
      , entry tally.maven "npc:the maven" [ View.Icon.maven, text "The Maven" ]
      , entry tally.maven "npc:the trialmaster" [ View.Icon.trialmaster, text "The Trialmaster" ]
      ]
        |> List.filter (\r -> r.count > 0)
        |> List.sortBy .count
        |> List.reverse
    , [ nonMapEntry tally.grandHeists "grand-heist:" [ View.Icon.grandHeistGeneric, text "Grand Heists" ]
      , nonMapEntry tally.heistContracts "heist-contract:" [ View.Icon.heistContractGeneric, text "Heist Contracts" ]
      , nonMapEntry tally.normalMaps "normal-map:" [ View.Icon.zana, text "Maps (non-unique, non-blighted)" ]
      , nonMapEntry tally.labyrinths "The Labyrinth" [ View.Icon.labTrial, text "The Labyrinth" ]
      , nonMapEntry tally.uniqueMaps "unique-map:" [ View.Icon.uniqueMap, text "Unique Maps" ]
      , nonMapEntry tally.blightedMaps "blighted" [ View.Icon.blightedMap, text "Blighted Maps" ]
      , nonMapEntry tally.mavenCrucibles "id:MavenHub" [ View.Icon.maven, text "The Maven's Crucible" ]
      , nonMapEntry tally.sirusFights "id:AtlasExilesBoss5" [ View.Icon.sirus, text "Eye of the Storm (Sirus)" ]
      ]
        |> List.filter (\r -> r.count > 0)
        |> List.sortBy .count
        |> List.reverse
    )
