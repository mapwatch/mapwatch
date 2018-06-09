module Route
    exposing
        ( Route(..)
        , HistoryParams
        , historyParams0
        , MapsParams
        , mapsParams0
        , TimerParams
        , timerParams0
        , OverlayParams
        , overlayParams0
        , parse
        , stringify
        , href
        , dateToString
        )

import Html as H
import Html.Attributes as A
import Navigation
import UrlParser as P exposing ((</>), (<?>))
import Http
import Regex
import Date as Date exposing (Date)
import Maybe.Extra


flags0 =
    { session = True, goals = False }


type alias HistoryParams =
    { page : Int, search : Maybe String, sort : Maybe String, after : Maybe Date, before : Maybe Date, goal : Maybe String, enableGoals : Bool }


historyParams0 =
    HistoryParams 0 Nothing Nothing Nothing Nothing Nothing flags0.goals


type alias MapsParams =
    { search : Maybe String, after : Maybe Date, before : Maybe Date }


mapsParams0 =
    MapsParams Nothing Nothing Nothing


type alias TimerParams =
    { after : Maybe Date, goal : Maybe String, enableSession : Bool, enableGoals : Bool }


timerParams0 =
    TimerParams Nothing Nothing flags0.session flags0.goals


type alias OverlayParams =
    { after : Maybe Date, goal : Maybe String, enableSession : Bool, enableGoals : Bool }


overlayParams0 =
    OverlayParams Nothing Nothing flags0.session flags0.goals


type Route
    = History HistoryParams
    | Maps MapsParams
    | Timer TimerParams
    | Overlay OverlayParams
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
        |> Debug.log "navigate to"


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


dateFromString : String -> Maybe Date
dateFromString =
    Result.toMaybe << Date.fromString


dateToString : Date -> String
dateToString d =
    -- compatible with dateFromString, identical to <input type="datetime-local">, and also reasonably short/user-readable
    ""
        -- autoformatter consistency
        ++ (String.join "-" <|
                List.map (\fn -> fn d)
                    [ toString << Date.year
                    , String.pad 2 '0' << toString << monthToInt << Date.month
                    , String.pad 2 '0' << toString << Date.day
                    ]
           )
        ++ "T"
        ++ (String.join ":" <|
                List.map (\fn -> String.pad 2 '0' <| toString <| fn d)
                    [ Date.hour
                    , Date.minute
                    , Date.second
                    ]
           )


dateParam : String -> P.QueryParser (Maybe Date -> a) a
dateParam name =
    P.customParam name <| Maybe.andThen dateFromString


boolParam : Bool -> String -> P.QueryParser (Bool -> a) a
boolParam default name =
    let
        parse : String -> Bool
        parse s =
            not <| s == "" || s == "0" || s == "no" || s == "n" || s == "False" || s == "false"
    in
        P.customParam name (Maybe.Extra.unwrap default parse)


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Timer <|
            P.map TimerParams <|
                (P.oneOf [ P.top, P.s "timer" ])
                    <?> dateParam "a"
                    <?> P.stringParam "g"
                    <?> boolParam flags0.session "enableSession"
                    <?> boolParam flags0.goals "enableGoals"
        , P.map Overlay <|
            P.map OverlayParams <|
                (P.oneOf [ P.top, P.s "overlay" ])
                    <?> dateParam "a"
                    <?> P.stringParam "g"
                    <?> boolParam flags0.session "enableSession"
                    <?> boolParam flags0.goals "enableGoals"
        , P.map History <|
            P.map (\p -> HistoryParams (Maybe.withDefault 0 p)) <|
                P.s "history"
                    <?> P.intParam "p"
                    <?> P.stringParam "q"
                    <?> P.stringParam "o"
                    <?> dateParam "a"
                    <?> dateParam "b"
                    <?> P.stringParam "g"
                    <?> boolParam flags0.goals "enableGoals"

        -- , P.map MapsRoot <| P.s "map"
        , P.map Maps <|
            P.map MapsParams <|
                P.s "map"
                    <?> P.stringParam "q"
                    <?> dateParam "a"
                    <?> dateParam "b"
        , P.map Changelog <| P.s "changelog"
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
                |> List.map (\( k, v ) -> Maybe.map (\v -> ( k, v )) v)
                |> Maybe.Extra.values
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
        History qs ->
            "#/history"
                ++ encodeQS
                    [ ( "p"
                      , if qs.page == 0 then
                            Nothing
                        else
                            Just <| toString qs.page
                      )
                    , ( "q", qs.search )
                    , ( "o", qs.sort )
                    , ( "a", Maybe.map dateToString qs.after )
                    , ( "b", Maybe.map dateToString qs.before )
                    , ( "g", qs.goal )
                    ]

        Maps qs ->
            "#/map"
                ++ encodeQS
                    [ ( "q", qs.search )
                    , ( "a", Maybe.map dateToString qs.after )
                    , ( "b", Maybe.map dateToString qs.before )
                    ]

        Timer qs ->
            "#/"
                ++ encodeQS
                    [ ( "a", Maybe.map dateToString qs.after )
                    , ( "g", qs.goal )
                    ]

        Overlay qs ->
            "#/overlay"
                ++ encodeQS
                    [ ( "a", Maybe.map dateToString qs.after )
                    , ( "g", qs.goal )
                    ]

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


monthToInt : Date.Month -> Int
monthToInt m =
    case m of
        Date.Jan ->
            1

        Date.Feb ->
            2

        Date.Mar ->
            3

        Date.Apr ->
            4

        Date.May ->
            5

        Date.Jun ->
            6

        Date.Jul ->
            7

        Date.Aug ->
            8

        Date.Sep ->
            9

        Date.Oct ->
            10

        Date.Nov ->
            11

        Date.Dec ->
            12
