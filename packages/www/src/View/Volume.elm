module View.Volume exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model as M exposing (Model, Msg)
import Route as Route exposing (Route)
import View.Icon as Icon


view : Model -> Html Msg
view { volume, route } =
    if Route.isSpeechEnabled route then
        div []
            -- without a fixed width, the volume-off/low/high icons are all different widths
            [ span [ style "display" "inline-block", style "width" "1em" ] [ Icon.fas (viewIconName volume) ]
            , text " Speech volume: "
            , input
                [ name "volume"
                , class "volume"
                , type_ "range"
                , A.min "0"
                , A.max "100"
                , value (String.fromInt volume)
                , onInput M.InputVolume
                ]
                []
            ]

    else
        div [] []


viewIconName : Int -> String
viewIconName volume =
    if volume == 0 then
        "volume-off"

    else if volume < 50 then
        "volume-down"

    else
        "volume-up"
