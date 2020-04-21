module View.Settings exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Model exposing (Msg, OkModel)
import Route exposing (Route)
import View.Home
import View.Nav
import View.Volume


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Volume.view model
        , button [ onClick (Model.Reset (Just Route.Timer)) ] [ Localized.text0 "settings-reset" ]
        , p [] [ Localized.text0 "changelog-opensource" ]
        , p [] [ a [ Route.href model.query Route.Privacy ] [ Localized.text0 "settings-privacy" ] ]
        , div [ class "debug-link" ] [ a [ Route.href model.query Route.Debug ] [ Localized.text0 "settings-debug" ] ]
        ]
