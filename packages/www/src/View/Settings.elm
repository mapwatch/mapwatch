module View.Settings exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model exposing (Msg, OkModel)
import Route exposing (Route)
import View.Home exposing (viewHeader)
import View.Nav
import View.Volume


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view model
        , View.Volume.view model
        , button [ onClick (Model.Reset (Just Route.Timer)) ] [ text "Analyze another Client.txt log file" ]
        , p [] [ text "Mapwatch is open source! ", a [ target "_blank", href "https://www.github.com/mapwatch/mapwatch" ] [ text "View the source code." ] ]
        , div [ class "debug-link" ] [ a [ Route.href model.query Route.Debug ] [ text "secret debugging tools" ] ]
        ]
