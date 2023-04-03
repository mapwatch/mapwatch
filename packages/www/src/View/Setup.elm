module View.Setup exposing (example, view, viewDownloadLink)

import AppPlatform
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Localization.Mapwatch as L
import Model exposing (Msg(..), OkModel)
import Route
import Route.Feature as Feature
import View.Volume


onChange : msg -> Attribute msg
onChange msg =
    on "change" <| Decode.succeed msg


viewDownloadLink : OkModel -> Html msg
viewDownloadLink model =
    if Feature.isActive Feature.DownloadLink model.query && not (AppPlatform.isElectron model || Feature.getBackendName model.query == Just "www-nativefs") then
        div [ class "electron-download" ] <|
            -- [ span [] [ View.Icon.fas "exclamation-triangle" ]
            [ div [ L.setupDownloadHeader ]
                [ a [ L.name_ "link", Route.downloadMapwatchHref ] []
                ]
            , div []
                [ small [ L.setupDownloadSubheader ]
                    [ a [ L.name_ "link", Route.fileWatchingHref ] []
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
        [ p [ L.setupDesc1 ]
            [ a [ L.name_ "link", target "_blank", href "https://www.pathofexile.com" ] []
            ]
        , if AppPlatform.isElectron model then
            -- electron - no link necessary, electron always live-updates
            p [ L.setupDesc2Www ] []

          else
            -- www, download-link - link to the mapwatch app
            p [ L.setupDesc2Electron ]
                [ a [ L.name_ "link", Route.downloadMapwatchHref ] []
                ]
        , p []
            [ a (AppPlatform.ifElectron model [] [ target "_blank" ] ++ [ href <| "/?example=" ++ example.file ++ example.query, L.setupExample ]) []
            ]
        , viewDownloadLink model
        , hr [] []
        , p []
            [ span [ L.setupFormMaxSizePre ] []
            , input
                [ A.name "input"
                , type_ "number"
                , value <| String.fromInt model.maxSize
                , onInput InputMaxSize
                , A.min "0"
                , A.max "200"
                , tabindex 1
                ]
                []
            , span [ L.setupFormMaxSizePost ] []
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
        [ span [ L.setupFormFileLabel ] []
        , button
            [ L.setupFormNativefsButton
            , type_ "button"
            , onClick FileSelector
            ]
            []
        , div [ L.setupFormNativefsHint1 ]
            [ a [ L.name_ "link", target "_blank", Route.fileWatchingHref ] []
            ]
        , div [ L.setupFormNativefsHint2 ] []
        , div [ L.setupFormNativefsHint3 ]
            [ a [ L.name_ "link-www", href "https://mapwatch.erosson.org" ] []
            , a [ L.name_ "link-download", target "_blank", Route.downloadMapwatchHref ] []
            ]
        ]

    else
        let
            id_ =
                "clientTxt"
        in
        [ span [ L.setupFormFileLabel ] []
        , input
            [ type_ "file"
            , id id_
            , onChange (LogSelected id_)
            , tabindex 2
            ]
            []
        , div []
            [ span [ L.setupFormFileHint ] []
            , br [] []
            , code [ L.setupFormFileHintPath1 ] []
            , br [] []
            , code [ L.setupFormFileHintPath2 ] []
            ]
        ]
