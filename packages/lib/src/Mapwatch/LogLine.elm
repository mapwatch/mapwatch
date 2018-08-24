module Mapwatch.LogLine exposing
    ( Info(..)
    , Line
    , ParseError
    , ParsedLine
    , parse
    )

import Maybe.Extra
import Regex
import Time
import Util exposing (regexParseFirst, regexParseFirstRes)


type alias ParseError =
    { raw : String, err : String }


type alias ParsedLine =
    Result ParseError Line


type Info
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String


type alias Line =
    { raw : String
    , date : Time.Posix
    , info : Info
    }


parseLogInfo : String -> Maybe Info
parseLogInfo raw =
    let
        parseOpening =
            case regexParseFirst "LOG FILE OPENING" raw of
                Just _ ->
                    Just Opening

                _ ->
                    Nothing

        parseEntered =
            case regexParseFirst "You have entered (.*)\\.$|你已進入：(.*)。$" raw |> Maybe.map (.submatches >> Maybe.Extra.values) of
                Just (zone :: _) ->
                    Just <| YouHaveEntered zone

                _ ->
                    Nothing

        parseConnecting =
            case regexParseFirst "Connecting to instance server at (.*)$" raw |> Maybe.map .submatches of
                Just [ Just addr ] ->
                    Just <| ConnectingToInstanceServer addr

                _ ->
                    Nothing
    in
    [ parseOpening, parseEntered, parseConnecting ]
        -- use the first matching parser
        |> Maybe.Extra.values
        |> List.head


parse : Time.Posix -> String -> ParsedLine
parse date raw =
    -- TODO this broke in elm 0.19: Date.fromString is gone. We don't really
    -- have a good way to parse dates anymore. On top of that, we'll need to
    -- apply the time zone somehow - but the new api doesn't easily let us map
    -- from timezone to time-offset. Ugh.
    let
        -- we used to parse the date here, but elm 0.19 broke it, and we now get
        -- the date via ports.
        result i =
            { raw = raw
            , date = date
            , info = i
            }

        info =
            parseLogInfo raw
                |> Result.fromMaybe "logline not recognized"

        error err =
            { err = err, raw = raw }
    in
    Result.map result info
        |> Result.mapError error
