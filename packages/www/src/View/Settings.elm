module View.Settings exposing (view, viewLocaleSelector)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Model exposing (Msg, OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import View.Home
import View.Nav
import View.Volume


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , View.Volume.view model
        , viewLocaleSelector model
        , button [ onClick (Model.Reset (Just Route.Timer)) ] [ Localized.text0 "settings-reset" ]
        , p [] [ Localized.text0 "changelog-opensource" ]
        , p [] [ a [ Route.href model.query Route.Privacy ] [ Localized.text0 "settings-privacy" ] ]
        , div [ class "debug-link" ] [ a [ Route.href model.query Route.Debug ] [ Localized.text0 "settings-debug" ] ]
        ]


viewLocaleSelector : OkModel -> Html Msg
viewLocaleSelector model =
    div [] <|
        if Feature.isActive Feature.Localization model.query then
            [ Localized.text0 "settings-locale-label"
            , text " "
            , select [ onInput Model.InputLocale ]
                (option [ value "" ] [ Localized.text0 "settings-locale-entry-default" ]
                    :: (model.flags.messages.bundles
                            |> List.map
                                (\( name, bun ) ->
                                    option [ value name, selected <| model.settings.locale == Just name ]
                                        [ Localized.text0 ("settings-locale-entry-" ++ name) ]
                                )
                       )
                )
            , text " "
            , small [] [ a [ target "_blank", href Route.translatorUrl ] [ Localized.text0 "settings-locale-volunteer" ] ]
            ]

        else
            []
