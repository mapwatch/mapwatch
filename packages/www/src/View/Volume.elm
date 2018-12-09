module View.Volume exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model as M exposing (Model, Msg)
import Route as Route exposing (Route)
import View.Icon as Icon


view : Model -> H.Html Msg
view { volume, route } =
    if Route.isSpeechEnabled route then
        H.div []
            -- without a fixed width, the volume-off/low/high icons are all different widths
            [ H.span [ A.style "display" "inline-block", A.style "width" "1em" ] [ Icon.fas (viewIconName volume) ]
            , H.text " Speech volume: "
            , H.input
                [ A.name "volume"
                , A.class "volume"
                , A.type_ "range"
                , A.min "0"
                , A.max "100"
                , A.value (String.fromInt volume)
                , E.onInput M.InputVolume
                ]
                []
            ]

    else
        H.div [] []


viewIconName : Int -> String
viewIconName volume =
    if volume == 0 then
        "volume-off"

    else if volume < 50 then
        "volume-down"

    else
        "volume-up"
