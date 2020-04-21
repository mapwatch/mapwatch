module View.NotFound exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Model exposing (OkModel)
import Route
import View.Home
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , Localized.text0 "notfound"
        ]
