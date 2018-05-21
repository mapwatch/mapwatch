module Model.Route exposing (Route(..), parse, stringify)

import Navigation
import UrlParser as P exposing ((</>))


type Route
    = Home
    | Debug
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
        ]


stringify : Route -> String
stringify route =
    case route of
        Home ->
            "#/"

        Debug ->
            "#/debug"

        NotFound loc ->
            loc.hash
