module View.Encounters exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Localized
import Mapwatch
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
import View.History
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
        [ View.Util.viewSearch [] model.query
        , View.Util.viewDateSearch model.query model.route
        , div [] <| viewEncounterTally model.query <| EncounterTally.fromMapRuns runs
        ]


viewEncounterTally : QueryDict -> EncounterTally -> List (Html msg)
viewEncounterTally query tally =
    [ table []
        [ thead []
            [ th [ style "text-align" "right" ] [ Localized.text0 "encounters-header-name" ]
            , th [] [ Localized.text0 "encounters-header-count" ]
            , th [] [ Localized.text "encounters-header-percent" [ Localized.int "count" tally.count ] ]
            ]
        , tbody []
            (tally
                |> listEncounterTally query
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
                            , td [] [ Localized.text "encounters-row-count" [ Localized.int "count" row.count ] ]
                            , td [] [ Localized.text "encounters-row-percent" [ Localized.float "percent" row.pct ] ]
                            ]
                    )
            )
        ]
    ]


listEncounterTally : QueryDict -> EncounterTally -> List { label : List (Html msg), count : Int, pct : Float, search : Maybe String }
listEncounterTally query tally =
    [ ( tally.abyssalDepths, "side:abyssal depths", [ View.Icon.abyss, Localized.text0 "encounters-name-abyssaldepths" ] )
    , ( tally.vaalAreas, "vaal-side:", [ View.Icon.vaal, Localized.text0 "encounters-name-vaalarea" ] )
    , ( tally.uniqueMaps, "unique-map:", [ View.Icon.uniqueMap, Localized.text0 "encounters-name-uniquemaps" ] )
    , ( tally.labTrialsTotal
      , "lab-trial-side:"
      , [ View.Icon.labTrial
        , Localized.text "encounters-name-labtrials" [ Localized.int "count" <| List.length tally.labTrials ]
        ]
      )
    , ( tally.conquerors
      , "conqueror:"
      , [ Localized.element "encounters-name-conquerors-title" [ "title" ] [] <|
            span [] [ View.Icon.sirus, Localized.text0 "encounters-name-conquerors" ]
        ]
      )
    , ( tally.blightedMaps, "blighted", [ View.Icon.blightedMap, Localized.text0 "encounters-name-blightedmaps" ] )
    , ( tally.zana, "npc:zana", [ View.Icon.zana, Localized.text0 "encounters-name-zana" ] )
    , ( tally.einhar, "npc:einhar", [ View.Icon.einhar, Localized.text0 "encounters-name-einhar" ] )
    , ( tally.alva, "npc:alva", [ View.Icon.alva, Localized.text0 "encounters-name-alva" ] )
    , ( tally.niko, "npc:niko", [ View.Icon.niko, Localized.text0 "encounters-name-niko" ] )
    , ( tally.jun, "npc:jun", [ View.Icon.jun, Localized.text0 "encounters-name-jun" ] )
    , ( tally.cassia, "npc:cassia", [ View.Icon.cassia, Localized.text0 "encounters-name-cassia" ] )
    ]
        ++ (if Feature.isActive Feature.DeliriumEncounter query then
                [ ( tally.delirium, "npc:strange voice", [ View.Icon.delirium, Localized.text0 "encounters-name-delirium" ] )
                ]

            else
                []
           )
        |> List.map
            (\( count, search, label ) ->
                { label = label
                , search =
                    if search == "" then
                        Nothing

                    else
                        Just search
                , count = count
                , pct = toFloat count / toFloat tally.count
                }
            )
        |> List.filter (\r -> r.count > 0)
        |> List.sortBy .count
        |> List.reverse
