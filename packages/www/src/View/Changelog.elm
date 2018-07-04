module View.Changelog exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Date as Date exposing (Date)
import Markdown
import Maybe.Extra
import Route as Route exposing (Route)
import View.Nav
import View.Icon as Icon
import View.Home exposing (viewHeader)


view : Maybe String -> H.Html msg
view markdown =
    H.div [ A.class "main" ]
        [ viewHeader
        , View.Nav.view <| Just Route.Changelog
        , H.div []
            [ H.text "Is something broken? "
            , H.a [ A.href "https://github.com/mapwatch/mapwatch/issues", A.target "_blank" ] [ H.text "File an issue on GitHub" ]
            , H.text " or "
            , H.a [ A.href "https://www.reddit.com/u/kawaritai", A.target "_blank" ] [ H.text "message the developer on Reddit" ]
            , H.text "."
            ]
        , H.div [ A.class "changelog-subscribe-buttons" ]
            [ H.a [ A.class "button", A.target "_blank", A.href "/rss.xml" ] [ Icon.fas "rss", H.text " RSS notifications" ]
            , H.a [ A.class "button", A.target "_blank", A.href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ Icon.fas "at", H.text " Email notifications" ]
            ]
        , markdown
            |> Maybe.andThen (String.split "---" >> List.drop 1 >> List.head)
            |> Maybe.Extra.unwrap (H.text "error fetching changelog") (Markdown.toHtml [ A.class "changelog-entries" ])
        ]
