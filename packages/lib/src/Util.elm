module Util exposing (regexParseFirst, regexParseFirstRes)

import Regex as Regex exposing (Regex)


unsafeRegex : String -> Regex
unsafeRegex string =
    case Regex.fromString string of
        Just regex ->
            regex

        Nothing ->
            Debug.todo "invalid regex" string


regexParseFirst : String -> String -> Maybe Regex.Match
regexParseFirst regex txt =
    txt
        |> Regex.findAtMost 1 (unsafeRegex regex)
        |> List.head


regexParseFirstRes : String -> err -> String -> Result err Regex.Match
regexParseFirstRes regex err txt =
    regexParseFirst regex txt |> Result.fromMaybe err
