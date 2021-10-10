module Page.Changelog exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Markdown
import Model exposing (OkModel)
import Route
import View.Home
import View.Icon
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , p [ L.settingsSource ] [ a [ A.attribute "data-l10n-name" "link", target "_blank", href "https://www.github.com/mapwatch/mapwatch" ] [] ]
        , p [ L.changelogReport ]
            [ a [ A.attribute "data-l10n-name" "link-keybase", href "https://keybase.io/erosson", target "_blank" ] []
            , a [ A.attribute "data-l10n-name" "link-issue", href "https://github.com/mapwatch/mapwatch/issues/new", target "_blank" ] []
            , a [ A.attribute "data-l10n-name" "link-reddit", href "https://www.reddit.com/u/kawaritai", target "_blank" ] []
            ]
        , p [ L.changelogApp ]
            [ a [ Route.appReleasesHref, target "_blank" ] []
            ]
        , div [ class "changelog-subscribe-buttons" ]
            [ a [ class "button", target "_blank", href "/rss.xml" ] [ View.Icon.fas "rss", text " ", span [ L.notifyRss ] [] ]
            , a [ class "button", target "_blank", href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ View.Icon.fas "at", text " ", span [ L.notifyEmail ] [] ]
            ]
        , model.flags.changelog
            -- skip everything above the first "---"
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml [ class "changelog-entries" ]
        ]
