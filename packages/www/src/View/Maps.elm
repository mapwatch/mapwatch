module View.Maps exposing (view)

import Dict
import Html as H
import Html.Attributes as A
import Html.Events as E
import Mapwatch as Mapwatch
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapList as MapList
import Mapwatch.Run as Run exposing (Run)
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


view : Route.MapsParams -> Model -> H.Html Msg
view params model =
    H.div [ A.class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.mapwatch.parseError
        , viewBody params model
        ]


viewBody : Route.MapsParams -> Model -> H.Html Msg
viewBody params model =
    case model.mapwatch.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
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


viewMain : Route.MapsParams -> Model -> H.Html Msg
viewMain params model =
    H.div []
        [ viewSearch [ A.placeholder "map name" ] (\q -> MapsSearch { params | search = Just q }) params.search
        , MapList.mapList
            |> search params.search
            |> Run.groupMapNames (Run.filterBetween params model.mapwatch.runs)
            |> List.reverse
            |> List.map ((\f ( a, b ) -> f a b) <| viewMap params)
            |> (\rows -> H.table [ A.class "by-map" ] [ H.tbody [] rows ])
        ]


viewMap : Route.MapsParams -> MapList.Map -> List Run -> H.Html msg
viewMap qs map runs =
    let
        durs =
            Run.meanDurationSet runs

        best =
            case Run.bestDuration .mainMap runs of
                Nothing ->
                    -- no runs - should be impossible, but not important enough to Debug.crash over it
                    "--:--"

                Just dur ->
                    formatDuration dur

        num =
            List.length runs
    in
    H.tr []
        ([ H.td [ A.class "zone" ] [ viewMapName qs map ]
         , H.td [] [ H.text <| "(T" ++ String.fromInt map.tier ++ ")" ]
         , H.td [] [ H.text <| formatDuration durs.mainMap ++ " per map" ]
         , H.td [] [ H.text <| String.fromFloat (roundToPlaces 2 durs.portals) ++ pluralize " portal" " portals" durs.portals ]
         , H.td [] [ H.text <| "×" ++ String.fromInt num ++ " runs." ]
         , H.td [] [ H.text <| "Best: " ++ best ]
         ]
         -- ++ (View.History.viewDurationSet <| )
        )


viewMapName : Route.MapsParams -> MapList.Map -> H.Html msg
viewMapName qs map =
    let
        hqs0 =
            Route.historyParams0
    in
    H.a [ Route.href <| Route.History { hqs0 | search = Just map.name, after = qs.after, before = qs.before } ] [ Icon.mapOrBlank map.name, H.text map.name ]
