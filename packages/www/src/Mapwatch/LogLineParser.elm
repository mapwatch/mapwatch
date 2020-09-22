module Mapwatch.LogLine exposing
    ( Info(..)
    , Line
    , ParseError
    , parse
    , parseErrorToString
    )

{-| A failed experiment.

Elm's parsers are nicer and more precise than regexes. They are also much slower.
Log processing speed matters very much to us. (I used no backtracking, too!)

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Maybe.Extra
import Parser as P exposing ((|.), (|=), Parser)
import Time exposing (Posix)
import Time.Extra


type alias ParseError =
    { raw : String, err : String }


parseErrorToString : ParseError -> String
parseErrorToString e =
    -- Debug.toString e
    "{ err: " ++ e.err ++ ", raw: " ++ e.raw ++ " }"


type Info
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String


type alias Line =
    { date : Posix
    , info : Info
    , raw : String
    }


parse : Datamine -> Time.Zone -> String -> Result ParseError Line
parse dm tz raw =
    P.run (parser dm tz) raw
        -- |> Result.mapError P.deadEndsToString
        |> Result.mapError Debug.toString
        |> Result.mapError (ParseError raw)


parser : Datamine -> Time.Zone -> P.Parser Line
parser dm tz =
    P.succeed Line
        |= dateParser tz
        |. P.spaces
        |= infoParser dm
        |. P.end
        |= P.getSource


infoParser : Datamine -> P.Parser Info
infoParser dm =
    P.oneOf
        [ infoOpeningParser

        -- Most logs have some "INFO Client 0123" nonsense at the beginning
        , P.succeed identity
            |. (P.chompUntil "]" |> P.getChompedString)
            |. P.symbol "]"
            |. P.spaces
            |= P.oneOf [ infoConnectingParser, infoEnteredParser dm ]
        ]


infoOpeningParser : P.Parser Info
infoOpeningParser =
    P.succeed Opening
        |. P.symbol "***** LOG FILE OPENING *****"


infoConnectingParser : P.Parser Info
infoConnectingParser =
    P.succeed ConnectingToInstanceServer
        |. P.symbol "Connecting to instance server at"
        |. P.spaces
        |= (P.chompWhile (\c -> Char.isDigit c || c == '.' || c == ':') |> P.getChompedString)


infoEnteredParser : Datamine -> P.Parser Info
infoEnteredParser dm =
    let
        strings : List ( String, String )
        strings =
            dm.lang
                |> Dict.values
                |> List.filterMap (\l -> Dict.get "EnteredArea" l.index.backendErrors)
                |> List.filterMap
                    (\s ->
                        case String.split "{0}" s of
                            pre :: suf :: [] ->
                                Just ( pre, suf )

                            _ ->
                                Nothing
                    )
    in
    P.succeed YouHaveEntered
        |. P.symbol ":"
        |. P.spaces
        |= P.oneOf
            (List.map
                (\( pre, suf ) ->
                    P.succeed identity
                        |. P.symbol pre
                        |= (P.chompUntil suf |> P.getChompedString)
                        |. P.symbol suf
                )
                strings
            )


dateParser : Time.Zone -> P.Parser Posix
dateParser tz =
    P.succeed Time.Extra.Parts
        -- example: `2020/01/08 16:12:56 ...`
        |= P.int
        |. P.symbol "/"
        |= intMonth
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


intMonth : P.Parser Time.Month
intMonth =
    leadingZeroInt
        |> P.andThen
            (\m ->
                Array.get (m - 1) months
                    |> Maybe.Extra.unwrap (P.problem <| "invalid month: " ++ String.fromInt m) P.succeed
            )


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
