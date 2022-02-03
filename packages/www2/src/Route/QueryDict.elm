module Route.QueryDict exposing
    ( QueryDict, fromString, fromUrlFragment, fromUrlQuery
    , toQueryParameters, toString, filterKeys
    , getPosix, insertPosix, getBool, insertBool, getInt, insertInt, getFloat, insertFloat
    )

{-| The query string, parsed as a dictionary.

I want to easily copy query string values among many different routes, ex. for
sitewide feature flags. This module sacrifices Elm's type-safety to do that.

@docs QueryDict, fromString, fromUrlFragment, fromUrlQuery
@docs toQueryParameters, toString, filterKeys
@docs getPosix, insertPosix, getBool, insertBool, getInt, insertInt, getFloat, insertFloat

-}

import Dict exposing (Dict)
import ISO8601
import Maybe.Extra
import Set exposing (Set)
import Time exposing (Posix)
import Url exposing (Url)
import Url.Builder


type alias QueryDict =
    Dict String String


fromUrlQuery : Url -> QueryDict
fromUrlQuery { query } =
    Maybe.Extra.unwrap Dict.empty fromString query


fromUrlFragment : Url -> QueryDict
fromUrlFragment url =
    url.fragment
        |> Maybe.withDefault ""
        |> String.split "?"
        |> List.drop 1
        |> List.head
        |> Maybe.Extra.unwrap Dict.empty fromString
        |> Dict.union (fromUrlQuery url)


fromString : String -> QueryDict
fromString =
    let
        parseEntry entry =
            case entry |> String.split "=" |> List.map Url.percentDecode |> Maybe.Extra.combine of
                Just [ k, v ] ->
                    Just ( k, v )

                _ ->
                    Nothing
    in
    String.split "&"
        >> List.filterMap parseEntry
        >> Dict.fromList


toQueryParameters : QueryDict -> List Url.Builder.QueryParameter
toQueryParameters =
    Dict.toList >> List.map (\( k, v ) -> Url.Builder.string k v)


toString : { prefix : Bool, filter : Maybe (Set String) } -> QueryDict -> String
toString { prefix, filter } d0 =
    -- no string.joins here - url.builder escapes properly
    let
        d =
            case filter of
                Nothing ->
                    d0

                Just keys ->
                    filterKeys keys d0

        s =
            d |> toQueryParameters |> Url.Builder.toQuery
    in
    if not prefix && String.startsWith "?" s then
        String.dropLeft 1 s

    else
        s


filterKeys : Set String -> QueryDict -> QueryDict
filterKeys keys =
    Dict.filter (\k _ -> Set.member k keys)



-- Query string parameters. This is not as nice/typesafe as Url.Parser, but
-- it is much easier to define feature flags, which is worth it to me.


getPosix : String -> QueryDict -> Maybe Posix
getPosix key =
    Dict.get key
        >> Maybe.andThen (ISO8601.fromString >> Result.toMaybe)
        >> Maybe.map ISO8601.toPosix


insertPosix : String -> Posix -> QueryDict -> QueryDict
insertPosix key val =
    Dict.insert key (val |> ISO8601.fromPosix |> ISO8601.toString)


getBool : String -> QueryDict -> Maybe Bool
getBool key =
    Dict.get key >> Maybe.map (\s -> not (s == "" || s == "0"))


insertBool : String -> Bool -> QueryDict -> QueryDict
insertBool key val =
    Dict.insert key
        (if val then
            "1"

         else
            ""
        )


getInt : String -> QueryDict -> Maybe Int
getInt key =
    Dict.get key >> Maybe.andThen String.toInt


insertInt : String -> Int -> QueryDict -> QueryDict
insertInt key val =
    Dict.insert key (String.fromInt val)


getFloat : String -> QueryDict -> Maybe Float
getFloat key =
    Dict.get key >> Maybe.andThen String.toFloat


insertFloat : String -> Float -> QueryDict -> QueryDict
insertFloat key val =
    Dict.insert key (String.fromFloat val)
