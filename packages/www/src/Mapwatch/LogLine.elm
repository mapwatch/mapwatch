module Mapwatch.LogLine exposing
    ( Info(..)
    , Line
    , ParseError
    , ParsedLine
    , parse
    , parseErrorToString
    )

import Array exposing (Array)
import Maybe.Extra
import Parser as P exposing ((|.), (|=), Parser)
import Regex
import Time exposing (Posix)
import Time.Extra


type alias ParseError =
    { raw : String, err : String }


parseErrorToString : ParseError -> String
parseErrorToString e =
    -- Debug.toString e
    "{ err: " ++ e.err ++ ", raw: " ++ e.raw ++ " }"


type alias ParsedLine =
    Result ParseError Line


type Info
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String


type alias Line =
    { raw : String
    , date : Posix
    , info : Info
    }


regexes =
    { opening = "LOG FILE OPENING" |> Regex.fromString
    , entered = "You have entered (.*)\\.$|你已進入：(.*)。$" |> Regex.fromString
    , connecting = "Connecting to instance server at (.*)$" |> Regex.fromString
    }


unsafeRegexes =
    { opening = regexes.opening |> Maybe.withDefault Regex.never
    , entered = regexes.entered |> Maybe.withDefault Regex.never
    , connecting = regexes.connecting |> Maybe.withDefault Regex.never
    }


parseLogInfo : String -> Maybe Info
parseLogInfo raw =
    let
        parseOpening =
            case raw |> Regex.findAtMost 1 unsafeRegexes.opening |> List.head of
                Just _ ->
                    Just Opening

                _ ->
                    Nothing

        parseEntered =
            case raw |> Regex.findAtMost 1 unsafeRegexes.entered |> List.head |> Maybe.map (.submatches >> Maybe.Extra.values) of
                Just (zone :: _) ->
                    Just <| YouHaveEntered zone

                _ ->
                    Nothing

        parseConnecting =
            case raw |> Regex.findAtMost 1 unsafeRegexes.connecting |> List.head |> Maybe.map .submatches of
                Just [ Just addr ] ->
                    Just <| ConnectingToInstanceServer addr

                _ ->
                    Nothing
    in
    [ parseOpening, parseEntered, parseConnecting ]
        -- use the first matching parser
        |> Maybe.Extra.values
        |> List.head


parseDate : Time.Zone -> String -> Result String Posix
parseDate tz raw =
    raw
        |> P.run (dateParser tz)
        -- |> Result.mapError P.deadEndsToString
        |> Result.mapError (Tuple.pair raw >> Debug.toString)
        -- |> Debug.log "parseDate"
        |> identity


dateParser : Time.Zone -> P.Parser Posix
dateParser tz =
    P.succeed Time.Extra.Parts
        -- example: `2020/01/08 16:12:56 ...`
        |= P.int
        |. P.symbol "/"
        |= (leadingZeroInt |> P.andThen (\m -> Array.get (m - 1) months |> Maybe.Extra.unwrap (P.problem <| "invalid month: " ++ String.fromInt m) P.succeed))
        |. P.symbol "/"
        |= leadingZeroInt
        |. P.spaces
        |= leadingZeroInt
        |. P.symbol ":"
        |= leadingZeroInt
        |. P.symbol ":"
        |= leadingZeroInt
        |. P.spaces
        |> P.map (\parts -> parts 0 |> Time.Extra.partsToPosix tz)


leadingZeroInt : P.Parser Int
leadingZeroInt =
    P.succeed identity
        |. P.oneOf
            [ P.symbol "0"
            , P.succeed ()
            ]
        |= P.int


months : Array Time.Month
months =
    Array.fromList
        [ Time.Jan
        , Time.Feb
        , Time.Mar
        , Time.Apr
        , Time.May
        , Time.Jun
        , Time.Jul
        , Time.Aug
        , Time.Sep
        , Time.Oct
        , Time.Nov
        , Time.Dec
        ]


parse : Time.Zone -> String -> ParsedLine
parse tz raw =
    case parseLogInfo raw of
        Nothing ->
            Err { raw = raw, err = "logline not recognized" }

        Just info ->
            case parseDate tz raw of
                Err err ->
                    Err { raw = raw, err = "logline date invalid: " ++ err }

                Ok date ->
                    Ok { raw = raw, date = date, info = info }
