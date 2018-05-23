module Model.Route exposing (Route(..), HistoryParams, parse, stringify, href)

import Html as H
import Html.Attributes as A
import Navigation
import UrlParser as P exposing ((</>))
import Http


type alias HistoryParams =
    { page : Int, search : String }


type Route
    = Home
    | HistoryRoot
    | History HistoryParams
    | Maps String
    | MapsRoot
    | Timer
    | Debug
    | DebugDumpLines
    | DebugMapIcons
    | NotFound Navigation.Location


parse : Navigation.Location -> Route
parse loc =
    P.parseHash parser loc
        |> Maybe.withDefault (NotFound loc)


decodeString : P.Parser (String -> a) a
decodeString =
    P.map
        (\s ->
            Http.decodeUri s
                -- |> Debug.log ("decode: " ++ s)
                |> Maybe.withDefault s
        )
        P.string


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Timer <| P.top
        , P.map Home <| P.s "legacy"
        , P.map Debug <| P.s "debug"
        , P.map DebugDumpLines <| P.s "debug" </> P.s "dumplines"
        , P.map DebugMapIcons <| P.s "debug" </> P.s "mapicons"
        , P.map HistoryRoot <| P.s "history"
        , P.map (\i -> HistoryParams i "" |> History) <| P.s "history" </> P.int
        , P.map (\i -> \s -> HistoryParams i s |> History) <| P.s "history" </> P.int </> decodeString
        , P.map MapsRoot <| P.s "map"
        , P.map Maps <| P.s "map" </> decodeString
        , P.map Timer <| P.s "timer"
        ]


stringify : Route -> String
stringify route =
    case route of
        Home ->
            "#/legacy"

        HistoryRoot ->
            "#/history"

        History { page, search } ->
            "#/history/" ++ toString page ++ "/" ++ Http.encodeUri search

        MapsRoot ->
            "#/map"

        Maps search ->
            "#/map/" ++ Http.encodeUri search

        Timer ->
            "#/"

        Debug ->
            "#/debug"

        DebugDumpLines ->
            "#/debug/dumplines"

        DebugMapIcons ->
            "#/debug/mapicons"

        NotFound loc ->
            loc.hash


href : Route -> H.Attribute msg
href =
    A.href << stringify
