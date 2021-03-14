module Page.Privacy exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import Maybe.Extra
import Model exposing (OkModel)
import Route as Route exposing (Route)
import View.Home
import View.Icon
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , model.flags.privacy |> Markdown.toHtml []
        ]
