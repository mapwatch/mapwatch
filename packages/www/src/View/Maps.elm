module View.Maps exposing (view)

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch as Mapwatch
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapList as MapList
import Mapwatch.Run as Run exposing (Run)
import Maybe.Extra
import Model as Model exposing (Model, Msg(..))
import Regex
import Route
import Time
import View.History
import View.Home exposing (formatDuration, formatSideAreaType, maskedText, viewDate, viewHeader, viewInstance, viewParseError, viewProgress, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util exposing (pluralize, roundToPlaces, viewSearch)
import View.Volume


view : Route.MapsParams -> Model -> Html Msg
view params model =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.mapwatch.parseError
        , viewBody params model
        ]


viewBody : Route.MapsParams -> Model -> Html Msg
viewBody params model =
    case model.mapwatch.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            div [] []

        Just p ->
            div [] <|
                (if Mapwatch.isProgressDone p then
                    -- all done!
                    [ viewMain params model ]

                 else
                    []
                )
                    ++ [ viewProgress p ]


search : Maybe String -> List MapList.Map -> List MapList.Map
search q ms =
    case q of
        Nothing ->
            ms

        Just q_ ->
            List.filter (.name >> Regex.contains (q_ |> Regex.fromStringWith { caseInsensitive = True, multiline = False } |> Maybe.withDefault Regex.never)) ms


sort : Maybe String -> List ( MapList.Map, Run.Summary ) -> List ( MapList.Map, Run.Summary )
sort o =
    let
        ( col, dir ) =
            case Maybe.map (String.split "-") o of
                Just [ c, "desc" ] ->
                    ( Just c, List.reverse )

                Just [ c, _ ] ->
                    ( Just c, identity )

                Just [ c ] ->
                    ( Just c, identity )

                _ ->
                    ( Nothing, identity )
    in
    (case col of
        Just "name" ->
            List.sortBy (Tuple.first >> .name)

        Just "tier" ->
            List.sortBy (Tuple.first >> .tier)

        Just "runs" ->
            List.sortBy (Tuple.second >> .num)

        Just "bestdur" ->
            List.sortBy (Tuple.second >> .best >> Maybe.withDefault 0)

        Just "meandur" ->
            List.sortBy (Tuple.second >> .durs >> .all)

        Just "portals" ->
            List.sortBy (Tuple.second >> .durs >> .portals)

        _ ->
            List.reverse
    )
        >> dir


viewMain : Route.MapsParams -> Model -> Html Msg
viewMain params model =
    case MapList.mapList of
        Err err ->
            pre [] [ text err ]

        Ok mapList ->
            let
                rows =
                    mapList
                        |> search params.search
                        |> Run.groupMapNames (Run.filterBetween params model.mapwatch.runs)
                        |> List.map (Tuple.mapSecond Run.summarize)
                        |> sort params.sort
                        |> List.map ((\f ( a, b ) -> f a b) <| viewMap params)
            in
            div []
                [ View.Volume.view model
                , viewSearch [ placeholder "map name" ] (\q -> MapsSearch { params | search = Just q }) params.search
                , table [ class "by-map" ]
                    [ thead [] [ header params ]
                    , tbody [] rows
                    ]
                ]


header : Route.MapsParams -> Html msg
header params =
    let
        cell : String -> String -> Html msg
        cell col label =
            th [] [ a [ headerHref col params ] [ text label ] ]
    in
    tr []
        [ cell "name" "Name"
        , cell "tier" "Tier"
        , cell "meandur" "Average"
        , cell "portals" "Portals"
        , cell "runs" "# Runs"
        , cell "bestdur" "Best"
        ]


headerHref : String -> Route.MapsParams -> Attribute msg
headerHref col params =
    Route.href <|
        Route.Maps
            { params
                | sort =
                    Just <|
                        if Just col == params.sort then
                            col ++ "-desc"

                        else
                            col
            }


viewMap : Route.MapsParams -> MapList.Map -> Run.Summary -> Html msg
viewMap qs map { durs, best, num } =
    tr []
        ([ td [ class "zone" ] [ viewMapName qs map ]
         , td [] [ text <| "(T" ++ String.fromInt map.tier ++ ")" ]
         , td [] [ text <| formatDuration durs.mainMap ++ " per map" ]
         , td [] [ text <| String.fromFloat (roundToPlaces 2 durs.portals) ++ pluralize " portal" " portals" durs.portals ]
         , td [] [ text <| "×" ++ String.fromInt num ++ " runs." ]
         , td [] [ text <| Maybe.Extra.unwrap "--:--" formatDuration best ++ " per map" ]
         ]
         -- ++ (View.History.viewDurationSet <| )
        )


viewMapName : Route.MapsParams -> MapList.Map -> Html msg
viewMapName qs map =
    let
        hqs0 =
            Route.historyParams0
    in
    a [ Route.href <| Route.History { hqs0 | search = Just map.name, after = qs.after, before = qs.before } ] [ Icon.mapOrBlank map.name, text map.name ]
