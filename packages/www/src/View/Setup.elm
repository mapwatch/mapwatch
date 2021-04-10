module View.Setup exposing (example, view, viewDownloadLink)

import AppPlatform
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Decode as Decode
import Model as Model exposing (Msg(..), OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import View.Icon
import View.Volume


onChange : msg -> Attribute msg
onChange msg =
    on "change" <| Decode.succeed msg


viewDownloadLink : OkModel -> Html msg
viewDownloadLink model =
    if Feature.isActive Feature.DownloadLink model.query && not (AppPlatform.isElectron model || Feature.getBackendName model.query == Just "www-nativefs") then
        div [ class "electron-download" ] <|
            -- [ span [] [ View.Icon.fas "exclamation-triangle" ]
            [ div []
                [ text "New: "
                , b []
                    [ a [ Route.downloadMapwatchHref ]
                        [ text "download Mapwatch" ]
                    ]
                , text " to see your maps updated while you play!"
                ]
            , div []
                [ small []
                    [ text " (Sadly, updates while you play will soon be "
                    , a [ target "_blank", Route.fileWatchingHref ]
                        [ text "unavailable" ]
                    , text " in all web browsers.) "
                    ]
                ]
            ]

    else
        div [] []


example =
    { file = "stripped-client.txt", query = "&tickStart=1526927461000&logtz=0#/" }


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
                ++ (case ( AppPlatform.isElectron model, Feature.isActive Feature.DownloadLink model.query ) of
                        ( True, _ ) ->
                            -- electron - no link necessary, electron always live-updates
                            []

                        ( False, True ) ->
                            -- www, download-link - link to the mapwatch app
                            [ a [ Route.downloadMapwatchHref ] [ text "if you're using the Mapwatch app" ], text ", " ]

                        ( False, False ) ->
                            -- www, no-download-link - chrome still works for now
                            [ a [ target "_blank", href "https://chrome.google.com" ] [ text "if you're using Google Chrome" ], text ", " ]
                   )
                ++ [ text "leave me open while you play - I'll keep watching, no need to upload again. " ]
            )
        , p []
            [ a (AppPlatform.ifElectron model [] [ target "_blank" ] ++ [ href <| "/?example=" ++ example.file ++ example.query ]) [ text "Run an example now!" ]
            ]
        , viewDownloadLink model
        , hr [] []
        , p []
            [ text "Analyze only the last "
            , input
                [ type_ "number"
                , value <| String.fromInt model.maxSize
                , onInput InputMaxSize
                , A.min "0"
                , A.max "100"
                , tabindex 1
                ]
                []
            , text " MB of history"
            ]
        , div [] <| viewFileSelector model
        , View.Volume.view model
        , div []
            (if model.flags.isBrowserSupported then
                []

             else
                [ text <| "Warning: we don't support your web browser. If you have trouble, try ", a [ href "https://www.google.com/chrome/" ] [ text "Chrome" ], text "." ]
            )

        -- uncomment and screenshot for a favicon.
        -- , div [ class "favicon-source" ] [ View.Icon.fas "stopwatch" ]
        ]


viewFileSelector : OkModel -> List (Html Msg)
viewFileSelector model =
    if Feature.getBackendName model.query == Just "www-nativefs" then
        [ text "Client.txt: "
        , button
            [ type_ "button"
            , onClick FileSelector
            ]
            [ text "Choose File" ]
        , div []
            [ text "Hint - "
            , a [ target "_blank", Route.fileWatchingHref ] [ text "read this first!" ]
            , text " This "
            , code [] [ text "nativefs" ]
            , text " version of Mapwatch needs some extra work."
            ]
        , div []
            [ text "If you've set things up properly, the file I need is here, near your item filters:"
            , br [] []
            , code [] [ text "C:\\Users\\%USERNAME%\\Documents\\My Games\\Path of Exile\\mapwatch.erosson.org---Client.txt" ]
            ]
        , div []
            [ text "Alternately, "
            , a [ href "https://mapwatch.erosson.org" ] [ text "use the original web version of Mapwatch" ]
            , text " (with no updates while you play), or "
            , a [ target "_blank", Route.downloadMapwatchHref ] [ text "download Mapwatch" ]
            , text "."
            ]
        , br [] []
        , br [] []
        ]

    else
        let
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
        ]
