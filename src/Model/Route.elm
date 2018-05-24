module Model.Route exposing (Route(..), HistoryParams, MapsParams, parse, stringify, href)

import Html as H
import Html.Attributes as A
import Navigation
import UrlParser as P exposing ((</>), (<?>))
import Http
import Regex


type alias HistoryParams =
    { page : Int, search : Maybe String, sort : Maybe String }


type alias MapsParams =
    { search : Maybe String, sort : Maybe String }


type Route
    = Home
    | HistoryRoot
    | History HistoryParams
    | MapsRoot
    | Maps MapsParams
    | Timer
    | Changelog
    | Debug
    | DebugDumpLines
    | DebugMapIcons
    | NotFound Navigation.Location


parse : Navigation.Location -> Route
parse loc =
    loc
        |> hashQS
        |> P.parseHash parser
        |> Maybe.withDefault (NotFound loc)


hashQS : Navigation.Location -> Navigation.Location
hashQS loc =
    -- UrlParser doesn't do ?query=strings in the #hash, so fake it using the non-hash querystring
    case Regex.split (Regex.AtMost 1) (Regex.regex "\\?") loc.hash of
        [ hash ] ->
            { loc | search = loc.search }

        [ hash, qs ] ->
            { loc | hash = hash, search = loc.search ++ "&" ++ qs }

        [] ->
            Debug.crash "hashqs: empty"

        other ->
            Debug.crash "hashqs: 3+"


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
        , P.map Timer <| P.s "timer"

        -- , P.map HistoryRoot <| P.s "history"
        , P.map History <| P.map (\p -> HistoryParams (Maybe.withDefault 0 p)) <| P.s "history" <?> P.intParam "p" <?> P.stringParam "q" <?> P.stringParam "o"

        -- , P.map MapsRoot <| P.s "map"
        , P.map Maps <| P.map MapsParams <| P.s "map" <?> P.stringParam "q" <?> P.stringParam "o"
        , P.map Changelog <| P.s "changelog"
        , P.map Home <| P.s "legacy"
        , P.map Debug <| P.s "debug"
        , P.map DebugDumpLines <| P.s "debug" </> P.s "dumplines"
        , P.map DebugMapIcons <| P.s "debug" </> P.s "mapicons"
        ]


encodeQS : List ( String, Maybe String ) -> String
encodeQS pairs0 =
    let
        pairs : List ( String, String )
        pairs =
            pairs0
                |> List.map (\( k, v ) -> Maybe.withDefault [] <| Maybe.map (\v -> [ ( k, v ) ]) v)
                |> List.concat
    in
        if List.isEmpty pairs then
            ""
        else
            pairs
                |> List.map (\( k, v ) -> Http.encodeUri k ++ "=" ++ Http.encodeUri v)
                |> String.join "&"
                |> (++) "?"


stringify : Route -> String
stringify route =
    case route of
        Home ->
            "#/legacy"

        HistoryRoot ->
            "#/history"

        History { page, search, sort } ->
            "#/history"
                ++ encodeQS
                    [ ( "p"
                      , if page == 0 then
                            Nothing
                        else
                            Just <| toString page
                      )
                    , ( "q", search )
                    , ( "o", sort )
                    ]

        MapsRoot ->
            "#/map"

        Maps { search, sort } ->
            "#/map" ++ encodeQS [ ( "q", search ), ( "o", sort ) ]

        Timer ->
            "#/"

        Changelog ->
            "#/changelog"

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
