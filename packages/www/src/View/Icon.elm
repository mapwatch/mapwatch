module View.Icon exposing (..)

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



-- fab =
-- fa "fab"


map : String -> Maybe (H.Html msg)
map name =
    let
        cls =
            Regex.replace Regex.All (Regex.regex "[ \t,:']+") (always "") name
    in
        MapList.url name
            |> Maybe.map (\src -> H.img [ A.class <| "map-icon map-icon-" ++ cls, A.src src ] [])


mapOrBlank : String -> H.Html msg
mapOrBlank name =
    map name
        |> Maybe.withDefault (H.span [] [])
