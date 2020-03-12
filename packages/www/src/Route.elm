module Route exposing
    ( Route(..)
    , downloadMapwatchHref
    , href
    , keys
    , parse
    , pushUrl
    , replaceUrl
    , toString
    )

import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Http
import ISO8601
import Maybe.Extra
import Regex
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Time exposing (Posix)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), (<?>))
import Url.Parser.Query as Q


type Route
    = History
    | HistoryTSV
    | GSheets
    | Maps
    | Timer
    | Overlay
    | Changelog
    | Privacy
    | Settings
    | Debug
    | DebugDumpLines
    | DebugDatamine
    | NotFound Url


parse : Url -> ( Route, QueryDict )
parse url =
    let
        route =
            parseRoute url

        ks =
            routeParts route |> Tuple.second
    in
    ( route
    , url
        |> QueryDict.fromUrlFragment
        |> QueryDict.filterKeys ks
    )


parseRoute : Url -> Route
parseRoute url =
    url
        |> hashUrl
        |> P.parse parser
        |> Maybe.withDefault (NotFound url)


hashUrl : Url -> Url
hashUrl url =
    -- elm 0.19 removed parseHash; booo. This function fakes it by transforming
    -- `https://example.com/?flag=1#/some/path?some=query` to
    -- `https://example.com/some/path?flag=1&some=query` for the parser.
    case url.fragment |> Maybe.withDefault "" |> String.split "?" of
        path :: queries ->
            let
                query =
                    queries |> String.join "?"

                urlQuery =
                    url.query |> Maybe.Extra.unwrap "" (\s -> s ++ "&")
            in
            { url | path = path, query = urlQuery ++ query |> Just }

        [] ->
            { url | path = "", query = url.query }


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Timer <| P.oneOf [ P.top, P.s "timer" ]
        , P.map Overlay <| P.s "overlay"
        , P.map History <| P.s "history"
        , P.map HistoryTSV <| P.s "history" </> P.s "tsv"
        , P.map GSheets <| P.s "gsheets"
        , P.map Maps <| P.s "map"
        , P.map Changelog <| P.s "changelog"
        , P.map Privacy <| P.s "privacy"
        , P.map Settings <| P.s "settings"
        , P.map Debug <| P.s "debug"
        , P.map DebugDumpLines <| P.s "debug" </> P.s "dumplines"
        , P.map DebugDatamine <| P.s "debug" </> P.s "datamine"
        ]


keys =
    { page = "p"
    , search = "q"
    , sort = "o"
    , before = "b"
    , after = "a"
    , goal = "g"
    }


pageKeys =
    { history = [ "p", "q", "o", "a", "b", "g" ] |> Set.fromList |> Set.union Feature.set
    , historyTSV = [ "q", "o", "a", "b" ] |> Set.fromList |> Set.union Feature.set
    , map = [ "q", "o", "a", "b" ] |> Set.fromList |> Set.union Feature.set
    , timer = [ "a", "g" ] |> Set.fromList |> Set.union Feature.set
    , overlay = [ "a" ] |> Set.fromList |> Set.union Feature.set
    , other = Feature.set
    }


routeParts : Route -> ( String, Set String )
routeParts r =
    case r of
        History ->
            ( "/history", pageKeys.history )

        HistoryTSV ->
            ( "/history/tsv", pageKeys.historyTSV )

        GSheets ->
            ( "/gsheets", pageKeys.other )

        Maps ->
            ( "/map", pageKeys.map )

        Timer ->
            ( "", pageKeys.timer )

        Overlay ->
            ( "/overlay", pageKeys.overlay )

        Changelog ->
            ( "/changelog", pageKeys.other )

        Privacy ->
            ( "/privacy", pageKeys.other )

        Settings ->
            ( "/settings", pageKeys.other )

        Debug ->
            ( "/debug", pageKeys.other )

        DebugDumpLines ->
            ( "/debug/dumplines", pageKeys.other )

        DebugDatamine ->
            ( "/debug/datamine", pageKeys.other )

        NotFound loc ->
            ( Maybe.withDefault "" loc.fragment, pageKeys.other )


toString : QueryDict -> Route -> String
toString query0 route =
    let
        ( path, queryKeys ) =
            routeParts route

        query =
            query0
                |> Feature.filterDefaults
                |> QueryDict.toString { prefix = True, filter = Just queryKeys }
    in
    "#" ++ path ++ query


href : QueryDict -> Route -> Attribute msg
href q =
    toString q >> A.href


pushUrl : Nav.Key -> QueryDict -> Route -> Cmd msg
pushUrl nav query =
    toString query >> Nav.pushUrl nav


replaceUrl : Nav.Key -> QueryDict -> Route -> Cmd msg
replaceUrl nav query =
    toString query >> Nav.replaceUrl nav


downloadMapwatchHref : Attribute msg
downloadMapwatchHref =
    A.href "https://github.com/mapwatch/mapwatch/releases"
