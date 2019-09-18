module View.Icon exposing (fa, fas, fasPulse, map, mapOrBlank)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Mapwatch.MapList as MapList
import Regex


fa : String -> String -> Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    span [ class <| icongroup ++ " fa-" ++ icon, property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fasPulse =
    fa "fa-spin fa-pulse fas"


map : String -> Maybe (Html msg)
map name =
    let
        cls =
            Regex.replace ("[ \t,:']+" |> Regex.fromString |> Maybe.withDefault Regex.never) (always "") name
    in
    MapList.url name
        |> Maybe.map (\src_ -> img [ class <| "map-icon map-icon-" ++ cls, src src_ ] [])


mapOrBlank : String -> Html msg
mapOrBlank name =
    map name
        |> Maybe.withDefault (span [] [])
