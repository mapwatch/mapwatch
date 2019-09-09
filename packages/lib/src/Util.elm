module Util exposing (regexParseFirst)

import Regex as Regex exposing (Regex)


regexParseFirst : String -> String -> Result String (Maybe Regex.Match)
regexParseFirst regexStr txt =
    case Regex.fromString regexStr of
        Nothing ->
            Err <| "invalid regex: " ++ regexStr

        Just regex ->
            txt
                |> Regex.findAtMost 1 regex
                |> List.head
                |> Ok
