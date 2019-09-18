module View.NotFound exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Route
import View.Home
import View.Nav


view : H.Html msg
view =
    H.div []
        [ View.Home.viewHeader
        , View.Nav.view Nothing
        , H.text "404"
        ]
