module View.Setup exposing (view, viewDownloadLink)

import AppPlatform
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Decode as Decode
import Localized
import Model as Model exposing (Msg(..), OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import View.Icon
import View.Settings
import View.Volume


onChange : msg -> Attribute msg
onChange msg =
    on "change" <| Decode.succeed msg


viewDownloadLink : OkModel -> Html msg
viewDownloadLink model =
    if Feature.isActive Feature.DownloadLink model.query && not (AppPlatform.isElectron model || Feature.getBackendName model.query == Just "www-nativefs") then
        div [ class "electron-download" ] <|
            -- [ span [] [ View.Icon.fas "exclamation-triangle" ]
            [ div [] [ Localized.text0 "setup-download-link" ]
            , div [] [ small [] [ Localized.text0 "setup-download-why" ] ]
            ]

    else
        div [] []


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
        [ p [] [ Localized.text0 "setup-intro1" ]
        , p []
            (case ( AppPlatform.isElectron model, Feature.isActive Feature.DownloadLink model.query ) of
                ( True, _ ) ->
                    -- electron - no link necessary, electron always live-updates
                    [ Localized.text0 "setup-electron-intro2" ]

                ( False, True ) ->
                    -- www, download-link - link to the mapwatch app
                    [ Localized.text0 "setup-www-download-intro2" ]

                ( False, False ) ->
                    -- www, no-download-link - chrome still works for now
                    [ Localized.text0 "setup-www-nodownload-intro2" ]
            )
        , p []
            [ a (AppPlatform.ifElectron model [] [ target "_blank" ] ++ [ href "?tickStart=1526927461000&logtz=0&example=stripped-client.txt#/" ]) [ Localized.text0 "setup-example" ]
            ]
        , viewDownloadLink model
        , hr [] []
        , p []
            -- TODO: splitting this up into 2 messages is super lame; this should be parameterizable
            [ Localized.text0 "setup-size-pre"
            , text " "
            , input
                [ type_ "number"
                , value <| String.fromInt model.config.maxSize
                , onInput InputMaxSize
                , A.min "0"
                , A.max "100"
                , tabindex 1
                ]
                []
            , text " "
            , Localized.text0 "setup-size-post"
            ]
        , div [] <| viewFileSelector model
        , br [] []
        , View.Volume.view model
        , View.Settings.viewLocaleSelector model
        , div []
            (if model.flags.isBrowserSupported then
                []

             else
                [ Localized.text0 "setup-badbrowser" ]
            )

        -- uncomment and screenshot for a favicon.
        -- , div [ class "favicon-source" ] [ View.Icon.fas "stopwatch" ]
        ]


viewFileSelector : OkModel -> List (Html Msg)
viewFileSelector model =
    if Feature.getBackendName model.query == Just "www-nativefs" then
        [ Localized.text0 "setup-filepicker"
        , text " "
        , button
            [ type_ "button"
            , onClick FileSelector
            ]
            [ Localized.text0 "setup-filepicker-native-button" ]
        , div [] [ Localized.text0 "setup-filepicker-native-help1" ]
        , div [] [ Localized.text0 "setup-filepicker-native-help2" ]
        , div [] [ Localized.text0 "setup-filepicker-native-help3" ]
        , br [] []
        ]

    else
        let
            id_ =
                "clientTxt"
        in
        [ Localized.text0 "setup-filepicker"
        , text " "
        , input
            [ type_ "file"
            , id id_
            , onChange (LogSelected id_)
            , tabindex 2
            ]
            []
        , div [] [ Localized.text0 "setup-filepicker-help" ]
        ]
