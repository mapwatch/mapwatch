module View.Setup exposing (view)

import AppPlatform
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Decode as Decode
import Model as Model exposing (Msg(..), OkModel)
import View.Icon as Icon
import View.Volume


onChange : msg -> Attribute msg
onChange msg =
    on "change" <| Decode.succeed msg


view : OkModel -> Html Msg
view model =
    let
        display =
            case model.mapwatch.readline of
                Nothing ->
                    ""

                Just _ ->
                    "none"
    in
    -- H.form [ onSubmit StartWatching ]
    H.form
        [ style "display" display ]
        [ p []
            [ text "Give me your "
            , a [ target "_blank", href "https://www.pathofexile.com" ] [ text "Path of Exile" ]
            , text " "
            , code [] [ text "Client.txt" ]
            , text " file, and I'll give you some statistics about your recent mapping activity. "
            ]
        , p []
            ([ text "Then, " ]
                ++ AppPlatform.ifElectron model [] [ a [ target "_blank", href "https://chrome.google.com" ] [ text "if you're using Google Chrome" ], text ", " ]
                ++ [ text "leave me open while you play - I'll keep watching, no need to upload again. " ]
            )
        , p []
            [ a (AppPlatform.ifElectron model [] [ target "_blank" ] ++ [ href "?tickStart=1526927461000&logtz=0&example=stripped-client.txt#/" ]) [ text "Run an example now!" ]
            ]
        , hr [] []
        , p []
            [ text "Analyze only the last "
            , input
                [ type_ "number"
                , value <| String.fromInt model.config.maxSize
                , onInput InputMaxSize
                , A.min "0"
                , A.max "100"
                , tabindex 1
                ]
                []
            , text " MB of history"
            ]
        , div []
            (let
                id_ =
                    "clientTxt"
             in
             [ text "Client.txt: "
             , input
                [ type_ "file"
                , id id_
                , onChange (LogSelected id_)
                , tabindex 2
                ]
                []
             , div []
                [ text "Hint - the file I need is usually in one of these places:"
                , br [] []
                , code [] [ text "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt" ]
                , br [] []
                , code [] [ text "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt" ]
                ]
             , View.Volume.view model
             ]
            )
        , div []
            (if model.flags.isBrowserSupported then
                []

             else
                [ text <| "Warning: we don't support your web browser. If you have trouble, try ", a [ href "https://www.google.com/chrome/" ] [ text "Chrome" ], text "." ]
            )

        -- uncomment and screenshot for a favicon.
        -- , div [ class "favicon-source" ] [ Icon.fas "stopwatch" ]
        ]
