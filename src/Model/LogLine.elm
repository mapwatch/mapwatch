module Model.LogLine exposing (ParseError, ParsedLine, Info(..), Line, parse)

import Date
import Regex
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
    , date : Date.Date
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
            case regexParseFirst "You have entered (.*)\\.$" raw |> Maybe.map .submatches of
                Just [ Just zone ] ->
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
            |> List.map (Maybe.withDefault [] << Maybe.map List.singleton)
            |> List.concat
            |> List.head


parse : String -> ParsedLine
parse raw =
    let
        date : Result String Date.Date
        date =
            raw
                -- rearrange the date so the built-in js parser likes it
                |> regexParseFirstRes "\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}" "no date in logline"
                |> Result.map (Regex.split Regex.All (Regex.regex "[/: ]") << .match)
                |> Result.andThen
                    (\strs ->
                        case strs of
                            [ yr, mo, d, h, mn, s ] ->
                                -- no time zone designator - assume local time.
                                -- This may act screwy around DST changes, but there's not much we can do -
                                -- logged dates are local-time with no info about the timezone at the time of logging.
                                Date.fromString <| (String.join "-" [ yr, mo, d ]) ++ "T" ++ (String.join ":" [ h, mn, s ])

                            _ ->
                                Err ("date parsed-count mismatch: " ++ toString strs)
                    )

        result d i =
            { raw = raw
            , date = d
            , info = i
            }

        info =
            parseLogInfo raw
                |> Result.fromMaybe "logline not recognized"

        error err =
            { err = err, raw = raw }
    in
        Result.map2 result date info
            |> Result.mapError error
