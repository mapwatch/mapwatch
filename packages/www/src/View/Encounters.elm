module View.Encounters exposing (view)

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
import View.Volume


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
        [ View.Volume.view model
        , View.Util.viewSearch [ placeholder "map name" ] model.query
        , div [] <| viewEncounterTally model.query <| EncounterTally.fromMapRuns runs
        ]


viewEncounterTally : QueryDict -> EncounterTally -> List (Html msg)
viewEncounterTally query tally =
    [ table []
        [ thead []
            [ th [ style "text-align" "right" ] [ text "Encounter" ]
            , th [] [ text "#" ]
            , th [] [ text "%" ]
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
                            , td [] [ text "×", text <| String.fromInt row.count ]
                            , td [] [ row.pct * 100 |> String.fromFloat |> String.left 5 |> text, text "%" ]
                            ]
                    )
            )
        ]
    ]


listEncounterTally : QueryDict -> EncounterTally -> List { label : List (Html msg), count : Int, pct : Float, search : Maybe String }
listEncounterTally query tally =
    [ ( tally.abyssalDepths, "", [ View.Icon.abyss, text "Abyssal Depths" ] )
    , ( tally.vaalAreas, "", [ View.Icon.vaal, text "Vaal side areas" ] )
    , ( tally.uniqueMaps, "", [ View.Icon.uniqueMap, text "Unique Maps" ] )
    , ( tally.labTrialsTotal, "", [ View.Icon.labTrial, text "(", text <| String.fromInt <| List.length tally.labTrials, text "/6) Labyrinth Trials" ] )
    , ( tally.blightedMaps, "blighted", [ View.Icon.cassia, text "Blighted Maps" ] )
    , ( tally.conquerors, "baran|veritania|hezmin|drox", [ span [ title "excluding Sirus" ] [ View.Icon.sirus, text "Conqueror Fights" ] ] )
    , ( tally.zana, "", [ View.Icon.zana, text "Zana" ] )
    , ( tally.einhar, "einhar", [ View.Icon.einhar, text "Einhar" ] )
    , ( tally.alva, "alva", [ View.Icon.alva, text "Alva" ] )
    , ( tally.niko, "niko", [ View.Icon.niko, text "Niko" ] )
    , ( tally.jun, "jun", [ View.Icon.jun, text "Jun" ] )
    , ( tally.cassia, "cassia", [ View.Icon.cassia, text "Cassia" ] )
    ]
        ++ (if Feature.isActive Feature.DeliriumEncounter query then
                [ ( tally.delirium, "delirium", [ View.Icon.delirium, text "Delirium" ] ) ]

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
