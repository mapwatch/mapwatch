module Model.Route exposing (Route(..), parse, stringify, href)

import Html as H
import Html.Attributes as A
import Navigation
import UrlParser as P exposing ((</>))


type Route
    = Home
    | HistoryRoot
    | History Int
    | Debug
    | DebugDumpLines
    | NotFound Navigation.Location


parse : Navigation.Location -> Route
parse loc =
    P.parseHash parser loc
        |> Maybe.withDefault (NotFound loc)


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Home <| P.top
        , P.map Debug <| P.s "debug"
        , P.map DebugDumpLines <| P.s "debug" </> P.s "dumplines"
        , P.map HistoryRoot <| P.s "history"
        , P.map History <| P.s "history" </> P.int
        ]


stringify : Route -> String
stringify route =
    case route of
        Home ->
            "#/"

        HistoryRoot ->
            "#/history"

        History page ->
            "#/history/" ++ toString page

        Debug ->
            "#/debug"

        DebugDumpLines ->
            "#/debug/dumplines"

        NotFound loc ->
            loc.hash


href : Route -> H.Attribute msg
href =
    A.href << stringify
