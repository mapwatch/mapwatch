module Util.String exposing (..)

import Regex exposing (Regex)


firstSubmatches : Regex -> String -> Maybe (List (Maybe String))
firstSubmatches re =
    Regex.findAtMost 1 re >> List.head >> Maybe.map .submatches


{-| Remove a prefix and suffix from a string, if it matches that prefix and suffix.

Most of our parsing doesn't need regexes!

-}
unwrap : String -> String -> String -> Maybe String
unwrap prefix suffix s =
    if startsAndEndsWith prefix suffix s then
        s
            |> String.dropLeft (String.length prefix)
            |> String.dropRight (String.length suffix)
            |> Just

    else
        Nothing


startsAndEndsWith : String -> String -> String -> Bool
startsAndEndsWith prefix suffix s =
    String.startsWith prefix s && String.endsWith suffix s


mapFirst : (a -> b) -> (b -> Bool) -> List a -> Maybe b
mapFirst map pred list =
    case list of
        [] ->
            Nothing

        head :: tail ->
            let
                val =
                    map head
            in
            if pred val then
                Just val

            else
                mapFirst map pred tail
