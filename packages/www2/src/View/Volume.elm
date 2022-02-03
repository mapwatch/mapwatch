module View.Volume exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Model as M exposing (Msg, OkModel)
import Route.Feature as Feature
import View.Icon as Icon


view : OkModel -> Html Msg
view { settings, route, query } =
    let
        { volume } =
            settings
    in
    if Feature.isActive Feature.Speech query then
        div []
            -- without a fixed width, the volume-off/low/high icons are all different widths
            [ span [ style "display" "inline-block", style "width" "1em" ] [ Icon.fas (viewIconName volume) ]
            , text " "
            , span [ L.setupSpeechVolume ] []
            , text " "
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
