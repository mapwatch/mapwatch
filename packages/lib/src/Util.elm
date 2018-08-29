module Util exposing (regexParseFirst, regexParseFirstRes)

import Regex


regexParseFirst : String -> String -> Maybe Regex.Match
regexParseFirst regex txt =
    txt
        |> Regex.find (Regex.AtMost 1) (Regex.regex regex)
        |> List.head


regexParseFirstRes : String -> err -> String -> Result err Regex.Match
regexParseFirstRes regex err txt =
    regexParseFirst regex txt |> Result.fromMaybe err
