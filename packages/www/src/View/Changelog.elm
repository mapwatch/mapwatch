module View.Changelog exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Markdown
import Maybe.Extra
import Model exposing (OkModel)
import Route as Route exposing (Route)
import View.Home
import View.Icon
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , p [] [ Localized.text0 "changelog-opensource" ]
        , p [] [ Localized.text0 "changelog-contactdev" ]
        , p [] [ Localized.text0 "changelog-app" ]
        , div [ class "changelog-subscribe-buttons" ]
            [ a [ class "button", target "_blank", href "/rss.xml" ] [ View.Icon.fas "rss", text " ", Localized.text0 "changelog-rss" ]
            , a [ class "button", target "_blank", href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ View.Icon.fas "at", text " ", Localized.text0 "changelog-email" ]
            ]

        -- Changelog text is deliberately not translated, it would slow me down too much
        , model.flags.changelog
            -- skip everything above the first "---"
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml [ class "changelog-entries" ]
        ]
