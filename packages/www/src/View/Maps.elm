module View.Maps exposing (view)

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Run as Run exposing (Run)
import Maybe.Extra
import Model as Model exposing (Msg(..), OkModel)
import Regex
import Route
import Time
import View.History
import View.Home exposing (formatDuration, maskedText, viewDate, viewHeader, viewInstance, viewParseError, viewProgress, viewSideAreaName)
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
        , viewParseError model.mapwatch.parseError
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


search : Maybe String -> List Run -> List Run
search mq =
    case mq of
        Nothing ->
            identity

        Just q ->
            Run.search q


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

        "tier" ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)

        "runs" ->
            List.sortBy (.runs >> .num)

        "bestdur" ->
            List.sortBy (.runs >> .best >> Maybe.withDefault 0)

        "meandur" ->
            List.sortBy (.runs >> .durs >> .all)

        "portals" ->
            List.sortBy (.runs >> .durs >> .portals)

        _ ->
            List.sortBy (.worldArea >> Datamine.tier >> Maybe.withDefault 0)
    )
        >> dir


type alias GroupedRuns =
    { name : String, worldArea : WorldArea, runs : Run.Summary }


viewMain : Route.MapsParams -> OkModel -> Html Msg
viewMain params model =
    let
        runs : List Run
        runs =
            model.mapwatch.runs
                |> search params.search
                |> Run.filterBetween params

        groupedRuns : List GroupedRuns
        groupedRuns =
            runs
                |> Run.groupByMap
                |> Dict.toList
                |> List.filterMap
                    (\( name, runGroup ) ->
                        model.mapwatch.datamine
                            |> Datamine.worldAreaFromName name
                            |> Maybe.map (\w -> { name = name, worldArea = w, runs = Run.summarize runGroup })
                    )

        rows : List (Html msg)
        rows =
            groupedRuns
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


viewMap : Route.MapsParams -> GroupedRuns -> Html msg
viewMap qs { name, worldArea, runs } =
    let
        { durs, best, num } =
            runs
    in
    tr []
        ([ td [ class "zone" ] [ viewMapName qs name worldArea ]
         , td []
            (case Datamine.tier worldArea of
                Nothing ->
                    []

                Just tier ->
                    [ text <| "(T" ++ String.fromInt tier ++ ")" ]
            )
         , td [] [ text <| formatDuration durs.mainMap ++ " per map" ]
         , td [] [ text <| String.fromFloat (roundToPlaces 2 durs.portals) ++ pluralize " portal" " portals" durs.portals ]
         , td [] [ text <| "×" ++ String.fromInt num ++ " runs." ]
         , td [] [ text <| Maybe.Extra.unwrap "--:--" formatDuration best ++ " per map" ]
         ]
         -- ++ (View.History.viewDurationSet <| )
        )


viewMapName : Route.MapsParams -> String -> WorldArea -> Html msg
viewMapName qs name worldArea =
    let
        hqs0 =
            Route.historyParams0
    in
    a [ Route.href <| Route.History { hqs0 | search = Just name, after = qs.after, before = qs.before } ] [ Icon.mapOrBlank (Just worldArea), text name ]
