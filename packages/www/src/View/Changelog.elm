module View.Changelog exposing (view)

import Date as Date exposing (Date)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Markdown
import Maybe.Extra
import Route as Route exposing (Route)
import View.Home exposing (viewHeader)
import View.Icon as Icon
import View.Nav


view : String -> Maybe String -> H.Html msg
view hrefHostname markdown =
    H.div [ A.class "main" ]
        [ viewHeader
        , View.Nav.view <| Just Route.Changelog
        , H.div []
            [ H.text "Is something broken? Contact the developer: "
            , H.a [ A.href "https://keybase.io/erosson", A.target "_blank" ] [ H.text "Keybase chat" ]
            , H.text ", "
            , H.a [ A.href "https://github.com/mapwatch/mapwatch/issues/new", A.target "_blank" ] [ H.text "GitHub issue" ]
            , H.text ", or "
            , H.a [ A.href "https://www.reddit.com/u/kawaritai", A.target "_blank" ] [ H.text "Reddit" ]
            , H.text "."
            ]
        , H.div [ A.class "changelog-subscribe-buttons" ]
            [ H.a [ A.class "button", A.target "_blank", A.href <| hrefHostname ++ "/rss.xml" ] [ Icon.fas "rss", H.text " RSS notifications" ]
            , H.a [ A.class "button", A.target "_blank", A.href "https://feedburner.google.com/fb/a/mailverify?uri=mapwatch" ] [ Icon.fas "at", H.text " Email notifications" ]
            ]
        , markdown
            |> Maybe.andThen (String.split "---" >> List.drop 1 >> List.head)
            |> Maybe.Extra.unwrap (H.text "error fetching changelog") (Markdown.toHtml [ A.class "changelog-entries" ])
        ]
