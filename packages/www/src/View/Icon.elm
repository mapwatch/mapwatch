module View.Icon exposing (fa, fas, fasPulse, map, mapOrBlank)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Encode as Json
import Mapwatch.MapList as MapList
import Regex


fa : String -> String -> H.Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    H.span [ A.class <| icongroup ++ " fa-" ++ icon, A.property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fasPulse =
    fa "fa-spin fa-pulse fas"


map : String -> Maybe (H.Html msg)
map name =
    let
        cls =
            Regex.replace ("[ \t,:']+" |> Regex.fromString |> Maybe.withDefault Regex.never) (always "") name
    in
    MapList.url name
        |> Maybe.map (\src -> H.img [ A.class <| "map-icon map-icon-" ++ cls, A.src src ] [])


mapOrBlank : String -> H.Html msg
mapOrBlank name =
    map name
        |> Maybe.withDefault (H.span [] [])
