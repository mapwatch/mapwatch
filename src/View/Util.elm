module View.Util exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import View.Icon as Icon


roundToPlaces : Float -> Float -> Float
roundToPlaces p n =
    (n * (10 ^ p) |> round |> toFloat) / (10 ^ p)


viewSearch : List (H.Attribute msg) -> (String -> msg) -> String -> H.Html msg
viewSearch attrs msg search =
    H.span [ A.class "search-text" ]
        [ H.input
            ([ A.value search
             , A.tabindex 1
             , E.onInput msg
             ]
                ++ attrs
            )
            []
        , Icon.fas "search"
        ]


pluralize : String -> String -> number -> String
pluralize one other n =
    if n == 1 then
        one
    else
        other
