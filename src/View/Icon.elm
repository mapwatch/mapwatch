module View.Icon exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Encode as Json


fa : String -> String -> H.Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    H.span [ A.class <| icongroup ++ " fa-" ++ icon, A.property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fasPulse =
    fa "fa-spin fa-pulse fas"



-- fab =
-- fa "fab"
