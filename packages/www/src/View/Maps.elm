module View.Maps exposing (view)

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Run2 as Run2 exposing (Run2)
import Mapwatch.Run2.Sort as RunSort
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Regex
import Route
import Time
import View.History
import View.Home exposing (formatDuration, maskedText, viewDate, viewHeader, viewInstance, viewProgress, viewRegion, viewSideAreaName)
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util exposing (pluralize, roundToPlaces, viewSearch)
import View.Volume


view : Route.MapsParams -> OkModel -> Html Msg
view params model =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewBody params model
        ]


viewBody : Route.MapsParams -> OkModel -> Html Msg
viewBody params model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            viewProgress p

        Mapwatch.Ready p ->
            div []
                [ viewMain params model
                , viewProgress p
                ]


search : Datamine -> Maybe String -> List Run2 -> List Run2
search dm mq =
    case mq of
        Nothing ->
            identity

        Just q ->
            RunSort.search dm q


{-| parse and apply the "?o=..." querytring parameter
-}
sort : Maybe String -> List GroupedRuns -> List GroupedRuns
sort o =
    let
        ( col, dir ) =
            case Maybe.map (String.split "-") o of
                Just [ c, "desc" ] ->
                    ( c, List.reverse )

                Just [ c, _ ] ->
                    ( c, identity )

                Just [ c ] ->
                    ( c, identity )

                _ ->
                    ( "runs", List.reverse )
    in
    (case col of
        "name" ->
            List.sortBy .name

        "region" ->
            List.sortBy (.worldArea >> .atlasRegion >> Maybe.withDefault Datamine.defaultAtlasRegion)

        "tier" ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)

        "runs" ->
            List.sortBy (.runs >> .num)

        "bestdur" ->
            List.sortBy (.runs >> .best >> .mainMap >> Maybe.withDefault 0)

        "meandur" ->
            List.sortBy (.runs >> .mean >> .duration >> .all)

        "portals" ->
            List.sortBy (.runs >> .mean >> .portals)

        _ ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)
    )
        >> dir


type alias GroupedRuns =
    { name : String, worldArea : WorldArea, runs : Run2.Aggregate }


viewMain : Route.MapsParams -> OkModel -> Html Msg
viewMain params model =
    let
        runs : List Run2
        runs =
            model.mapwatch.runs
                |> search model.mapwatch.datamine params.search
                |> RunSort.filterBetween params

        rows : List (Html msg)
        rows =
            runs
                |> groupRuns model.mapwatch.datamine
                |> sort params.sort
                |> List.map (viewMap params)
    in
    div []
        [ View.Volume.view model
        , viewSearch [ placeholder "map name" ] (\q -> MapsSearch { params | search = Just q }) params.search
        , table [ class "by-map" ]
            [ thead [] [ header params ]
            , tbody [] rows
            ]
        ]


groupRuns : Datamine -> List Run2 -> List GroupedRuns
groupRuns dm =
    RunSort.groupByMap
        >> Dict.toList
        >> List.filterMap
            (\( name, runGroup ) ->
                Datamine.worldAreaFromName name dm
                    |> Maybe.map (\w -> { name = name, worldArea = w, runs = Run2.aggregate runGroup })
            )


header : Route.MapsParams -> Html msg
header params =
    let
        cell : String -> String -> Html msg
        cell col label =
            th [] [ a [ headerHref col params ] [ text label ] ]
    in
    tr []
        [ cell "name" "Name"
        , cell "region" "Region"
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


viewMap : Route.MapsParams -> GroupedRuns -> Html msg
viewMap qs { name, worldArea, runs } =
    let
        { mean, best, num } =
            runs
    in
    tr []
        [ td [ class "zone" ] [ viewMapName qs name worldArea ]
        , td [] [ viewRegionName qs worldArea ]
        , td []
            (case Datamine.tier worldArea of
                Nothing ->
                    []

                Just tier ->
                    [ text <| "(T" ++ String.fromInt tier ++ ")" ]
            )
        , td [] [ text <| formatDuration mean.duration.mainMap ++ " per map" ]
        , td [] [ text <| String.fromFloat (roundToPlaces 2 mean.portals) ++ pluralize " portal" " portals" mean.portals ]
        , td [] [ text <| "×" ++ String.fromInt num ++ " runs." ]
        , td [] [ text <| Maybe.Extra.unwrap "--:--" formatDuration best.mainMap ++ " per map" ]
        ]


viewRegionName : Route.MapsParams -> WorldArea -> Html msg
viewRegionName qs w =
    let
        hqs0 =
            Route.historyParams0

        name =
            w.atlasRegion |> Maybe.withDefault Datamine.defaultAtlasRegion
    in
    viewRegion { hqs0 | search = Just name, after = qs.after, before = qs.before } (Just w)


viewMapName : Route.MapsParams -> String -> WorldArea -> Html msg
viewMapName qs name worldArea =
    let
        hqs0 =
            Route.historyParams0
    in
    a [ Route.href <| Route.History { hqs0 | search = Just name, after = qs.after, before = qs.before } ]
        [ Icon.mapOrBlank { isBlightedMap = False } (Just worldArea), text name ]
