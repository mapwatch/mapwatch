module View.MapIcons exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch.MapList exposing (Map, mapList)
import View.Icon as Icon


view : Html msg
view =
    case mapList of
        Err err ->
            pre [] [ text err ]

        Ok list ->
            ul [] (List.map viewMap list)


viewMap : Map -> Html msg
viewMap map =
    li [] [ Icon.mapOrBlank map.name, text map.name ]
