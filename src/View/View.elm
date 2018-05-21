module View.View exposing (view)

import Html as H
import Model as Model exposing (Model, Msg)
import Model.Route as Route exposing (Route(..))
import View.Home


view : Model -> H.Html Msg
view model =
    case model.route of
        Home ->
            View.Home.view model

        Debug ->
            H.div [] [ H.text "TODO" ]

        NotFound _ ->
            H.div [] [ H.text "404'ed" ]
