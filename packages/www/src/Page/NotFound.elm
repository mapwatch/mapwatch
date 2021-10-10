module Page.NotFound exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Model exposing (OkModel)
import View.Home
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , span [ L.notFound ] []
        ]
