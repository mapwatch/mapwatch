module View.Icon exposing (fa, fas, fasPulse, map, mapOrBlank)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Regex


fa : String -> String -> Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    span [ class <| icongroup ++ " fa-" ++ icon, property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fasPulse =
    fa "fa-spin fa-pulse fas"


map : Maybe WorldArea -> Maybe (Html msg)
map =
    Maybe.andThen
        (\world ->
            world
                |> Datamine.imgSrc
                |> Maybe.map (\src_ -> img [ class <| "map-icon map-icon-" ++ world.id, src src_ ] [])
        )


mapOrBlank : Maybe WorldArea -> Html msg
mapOrBlank =
    map >> Maybe.withDefault (span [] [])
