module View.NotFound exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E


view : H.Html msg
view =
    H.div [] [ H.text "404" ]
