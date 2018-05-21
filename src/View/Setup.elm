module View.Setup exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
import Model as Model exposing (Model, Msg(..))


onChange : msg -> H.Attribute msg
onChange msg =
    E.on "change" <| Decode.succeed msg


view : Model -> H.Html Msg
view model =
    let
        display =
            case model.progress of
                Nothing ->
                    ""

                Just _ ->
                    "none"
    in
        -- H.form [ E.onSubmit StartWatching ]
        H.form
            [ A.style [ ( "display", display ) ] ]
            [ H.p []
                [ H.text "Give me your "
                , H.a [ A.target "_blank", A.href "https://www.pathofexile.com" ] [ H.text "Path of Exile" ]
                , H.text " "
                , H.code [] [ H.text "Client.txt" ]
                , H.text " file, and I'll give you some statistics about your recent mapping activity. "
                ]
            , H.p []
                [ H.text "Then, "
                , H.a [ A.target "_blank", A.href "https://chrome.google.com" ] [ H.text "if you're using Google Chrome" ]
                , H.text ", leave me open while you play - I'll keep watching, no need to upload again. "
                ]
            , H.p []
                [ H.a [ A.target "_blank", A.href "?tickStart=<Sat%20May%2019%202018%2018:20:12%20GMT-0400%20(EDT)>&example=stripped-client.txt#/history" ] [ H.text "See an example." ]
                ]
            , H.hr [] []
            , H.p []
                [ H.text "Analyze only the last "
                , H.input
                    [ A.type_ "number"
                    , A.value <| toString model.config.maxSize
                    , E.onInput InputMaxSize
                    , A.min "0"
                    , A.max "100"
                    , A.tabindex 1
                    ]
                    []
                , H.text " MB of history"
                ]
            , H.div []
                (let
                    id =
                        "clientTxt"
                 in
                    [ H.text "Client.txt: "
                    , H.input
                        [ A.type_ "file"
                        , A.id id
                        , onChange (InputClientLogWithId id)
                        , A.tabindex 2
                        ]
                        []
                    , H.div []
                        [ H.text "Hint - the file I need is usually in one of these places:"
                        , H.br [] []
                        , H.code [] [ H.text "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt" ]
                        , H.br [] []
                        , H.code [] [ H.text "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt" ]
                        ]
                    ]
                )
            , H.div []
                (if model.flags.isBrowserSupported then
                    []
                 else
                    [ H.text <| "Warning: we don't support your web browser. If you have trouble, try ", H.a [ A.href "https://www.google.com/chrome/" ] [ H.text "Chrome" ], H.text "." ]
                )
            ]
