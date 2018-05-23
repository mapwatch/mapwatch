module View.MapIcons exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.MapList exposing (Map, mapList)
import View.Icon as Icon


view : H.Html msg
view =
    H.ul [] (List.map viewMap mapList)


viewMap : Map -> H.Html msg
viewMap map =
    H.li [] [ Icon.mapOrBlank map.name, H.text map.name ]
