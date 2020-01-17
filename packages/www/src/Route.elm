module Route exposing
    ( HistoryParams
    , MapsParams
    , OverlayParams
    , Route(..)
    , TimerParams
    , dateToString
    , flags0
    , historyParams0
    , href
    , isSpeechEnabled
    , mapsParams0
    , overlayParams0
    , parse
    , root
    , stringify
    , timerParams0
    )

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Http
import ISO8601
import Maybe.Extra
import Regex
import Time exposing (Posix)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), (<?>))
import Url.Parser.Query as Q


flags0 =
    { goals = True
    , speech = False
    }


type alias HistoryParams =
    { page : Int
    , search : Maybe String
    , sort : Maybe String
    , after : Maybe Posix
    , before : Maybe Posix
    , goal : Maybe String
    , enableGoals : Bool
    , enableSpeech : Bool
    }


historyParams0 : HistoryParams
historyParams0 =
    HistoryParams 0 Nothing Nothing Nothing Nothing Nothing flags0.goals flags0.speech


type alias MapsParams =
    { search : Maybe String
    , sort : Maybe String
    , after : Maybe Posix
    , before : Maybe Posix
    , enableSpeech : Bool
    }


mapsParams0 : MapsParams
mapsParams0 =
    MapsParams Nothing Nothing Nothing Nothing flags0.speech


type alias TimerParams =
    { after : Maybe Posix
    , goal : Maybe String
    , enableGoals : Bool
    , enableSpeech : Bool
    }


timerParams0 : TimerParams
timerParams0 =
    TimerParams Nothing Nothing flags0.goals flags0.speech


type alias OverlayParams =
    { after : Maybe Posix
    , goal : Maybe String
    , enableGoals : Bool
    , enableSpeech : Bool
    }


overlayParams0 : OverlayParams
overlayParams0 =
    OverlayParams Nothing Nothing flags0.goals flags0.speech


type Route
    = History HistoryParams
    | Maps MapsParams
    | Timer TimerParams
    | Overlay OverlayParams
    | Changelog
    | Settings
    | Debug
    | DebugDumpLines
    | DebugDatamine
    | NotFound Url


parse : Url -> Route
parse loc =
    loc
        |> hashUrl
        |> P.parse parser
        |> Maybe.withDefault (NotFound loc)



-- |> Debug.log "navigate to"


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


decodeString : P.Parser (String -> a) a
decodeString =
    P.map
        (\s ->
            s
                |> Url.percentDecode
                |> Maybe.withDefault s
        )
        P.string


dateFromString : String -> Maybe Posix
dateFromString =
    ISO8601.fromString >> Result.toMaybe >> Maybe.map ISO8601.toPosix


dateToString : Posix -> String
dateToString =
    -- compatible with dateFromString, identical to <input type="datetime-local">, and also reasonably short/user-readable
    ISO8601.fromPosix >> ISO8601.toString


dateParam : String -> Q.Parser (Maybe Posix)
dateParam name =
    Q.custom name (List.head >> Maybe.andThen dateFromString)


boolParam : Bool -> String -> Q.Parser Bool
boolParam default name =
    let
        parse_ : String -> Bool
        parse_ s =
            not <| s == "" || s == "0" || s == "no" || s == "n" || s == "False" || s == "false"
    in
    Q.custom name (List.head >> Maybe.Extra.unwrap default parse_)


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Timer <|
            P.map TimerParams <|
                P.oneOf [ P.top, P.s "timer" ]
                    <?> dateParam "a"
                    <?> Q.string "g"
                    <?> boolParam flags0.goals "enableGoals"
                    <?> boolParam flags0.speech "enableSpeech"
        , P.map Overlay <|
            P.map OverlayParams <|
                P.oneOf [ P.top, P.s "overlay" ]
                    <?> dateParam "a"
                    <?> Q.string "g"
                    <?> boolParam flags0.goals "enableGoals"
                    <?> boolParam flags0.speech "enableSpeech"
        , P.map History <|
            P.map (\p -> HistoryParams (Maybe.withDefault 0 p)) <|
                P.s "history"
                    <?> Q.int "p"
                    <?> Q.string "q"
                    <?> Q.string "o"
                    <?> dateParam "a"
                    <?> dateParam "b"
                    <?> Q.string "g"
                    <?> boolParam flags0.goals "enableGoals"
                    <?> boolParam flags0.speech "enableSpeech"

        -- , P.map MapsRoot <| P.s "map"
        , P.map Maps <|
            P.map MapsParams <|
                P.s "map"
                    <?> Q.string "q"
                    <?> Q.string "o"
                    <?> dateParam "a"
                    <?> dateParam "b"
                    <?> boolParam flags0.speech "enableSpeech"
        , P.map Changelog <| P.s "changelog"
        , P.map (always Changelog) <| P.s "changelog" </> P.string
        , P.map Settings <| P.s "settings"
        , P.map Debug <| P.s "debug"
        , P.map DebugDumpLines <| P.s "debug" </> P.s "dumplines"
        , P.map DebugDatamine <| P.s "debug" </> P.s "datamine"
        ]


encodeQS : List ( String, Maybe String ) -> String
encodeQS pairs0 =
    let
        pairs : List ( String, String )
        pairs =
            pairs0
                |> List.map (\( k, v ) -> Maybe.map (\vv -> ( k, vv )) v)
                |> Maybe.Extra.values
    in
    if List.isEmpty pairs then
        ""

    else
        pairs
            -- TODO should really rewrite to use elm-0.19's Url.Builder instead of Url.percentEncode;
            -- I'm just too lazy to redesign this while migrating everything else to 0.19
            |> List.map (\( k, v ) -> Url.percentEncode k ++ "=" ++ Url.percentEncode v)
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
                            qs.page |> String.fromInt |> Just
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
                    , ( "o", qs.sort )
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

        Settings ->
            "#/settings"

        Debug ->
            "#/debug"

        DebugDumpLines ->
            "#/debug/dumplines"

        DebugDatamine ->
            "#/debug/datamine"

        NotFound loc ->
            "#" ++ (loc.fragment |> Maybe.withDefault "")


root : Route
root =
    Timer timerParams0


href : Route -> Attribute msg
href =
    A.href << stringify


{-| Unlike most flags, we check this one from many possible routes, not just one
-}
isSpeechEnabled : Route -> Bool
isSpeechEnabled route =
    case route of
        Timer { enableSpeech } ->
            enableSpeech

        History { enableSpeech } ->
            enableSpeech

        Maps { enableSpeech } ->
            enableSpeech

        Overlay { enableSpeech } ->
            enableSpeech

        _ ->
            flags0.speech
