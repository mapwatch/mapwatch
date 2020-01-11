module View.Changelog exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import Maybe.Extra
import Route as Route exposing (Route)
import View.Home exposing (viewHeader)
import View.Icon as Icon
import View.Nav


view : String -> Html msg
view markdown =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view <| Just Route.Changelog
        , div []
            [ text "Is something broken? Contact the developer: "
            , a [ href "https://keybase.io/erosson", target "_blank" ] [ text "Keybase chat" ]
            , text ", "
            , a [ href "https://github.com/mapwatch/mapwatch/issues/new", target "_blank" ] [ text "GitHub issue" ]
            , text ", or "
            , a [ href "https://www.reddit.com/u/kawaritai", target "_blank" ] [ text "Reddit" ]
            , text "."
            ]
        , div [ class "changelog-subscribe-buttons" ]
            [ a [ class "button", target "_blank", href "/rss.xml" ] [ Icon.fas "rss", text " RSS notifications" ]
            , a [ class "button", target "_blank", href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ Icon.fas "at", text " Email notifications" ]
            ]
        , markdown
            -- skip everything above the first "---"
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml [ class "changelog-entries" ]
        ]
