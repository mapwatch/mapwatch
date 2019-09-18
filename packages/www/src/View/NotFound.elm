module View.NotFound exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route
import View.Home
import View.Nav


view : Html msg
view =
    div []
        [ View.Home.viewHeader
        , View.Nav.view Nothing
        , text "404"
        ]
