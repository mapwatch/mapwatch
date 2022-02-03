module Page.Settings exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Model exposing (Msg, OkModel)
import Route
import View.Home
import View.Nav
import View.Volume


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Volume.view model
        , button [ onClick (Model.Reset (Just Route.Timer)), L.settingsReset ] []
        , p [ L.settingsSource ] [ a [ L.name_ "link", target "_blank", href "https://www.github.com/mapwatch/mapwatch" ] [] ]
        , p [] [ a [ Route.href model.query Route.Privacy, L.settingsPrivacy ] [] ]
        , div [ class "debug-link" ] [ a [ Route.href model.query Route.Debug ] [ text "secret debugging tools" ] ]
        ]
