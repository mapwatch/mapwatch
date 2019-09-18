module View.DumpLines exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model as Model exposing (Model, Msg)
import View.Setup


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ View.Setup.view model
        , pre [] (List.map viewLine <| List.reverse model.lines)
        ]


viewLine line =
    text <| line ++ "\n"
