module Page.Changelog exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
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
        , p [] [ text "Mapwatch is open source! ", a [ target "_blank", href "https://www.github.com/mapwatch/mapwatch" ] [ text "View the source code." ] ]
        , p []
            [ text "Is something broken? Contact the developer: "
            , a [ href "https://keybase.io/erosson", target "_blank" ] [ text "Keybase chat" ]
            , text ", "
            , a [ href "https://github.com/mapwatch/mapwatch/issues/new", target "_blank" ] [ text "GitHub issue" ]
            , text ", or "
            , a [ href "https://www.reddit.com/u/kawaritai", target "_blank" ] [ text "Reddit" ]
            , text "."
            ]
        , p []
            [ text "Changes listed below affect both the Mapwatch website and the Mapwatch app. "
            , a [ Route.appReleasesHref, target "_blank" ] [ text "The app sometimes has additional changes, listed on its releases page." ]
            ]
        , div [ class "changelog-subscribe-buttons" ]
            [ a [ class "button", target "_blank", href "/rss.xml" ] [ View.Icon.fas "rss", text " RSS notifications" ]
            , a [ class "button", target "_blank", href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ View.Icon.fas "at", text " Email notifications" ]
            ]
        , model.flags.changelog
            -- skip everything above the first "---"
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml [ class "changelog-entries" ]
        ]
