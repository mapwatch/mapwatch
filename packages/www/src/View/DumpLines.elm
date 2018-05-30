module View.DumpLines exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model as Model exposing (Model, Msg)
import View.Setup


view : Model -> H.Html Msg
view model =
    H.div []
        [ View.Setup.view model
        , H.pre [] (List.map viewLine <| List.reverse model.lines)
        ]


viewLine line =
    H.text <| line ++ "\n"
