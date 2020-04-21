module View.Nav exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import View.Icon as Icon


view : { a | query : QueryDict, route : Route } -> Html msg
view ({ query, route } as model) =
    nav []
        [ a (linkAttrs model Route.Timer) [ Icon.fas "stopwatch", text " ", Localized.text0 "nav-timer" ]
        , a (linkAttrs model Route.History) [ Icon.fas "history", text " ", Localized.text0 "nav-history" ]
        , a (linkAttrs model Route.Maps) [ Icon.fas "map", text " ", Localized.text0 "nav-maps" ]
        , a (linkAttrs model Route.Encounters) [ Icon.fas "directions", text " ", Localized.text0 "nav-encounters" ]
        , a (linkAttrs model Route.Changelog) [ Icon.fas "newspaper", text " ", Localized.text0 "nav-changelog" ]
        , a (linkAttrs model Route.Settings) [ Icon.fas "cog", text " ", Localized.text0 "nav-settings" ]
        ]


linkAttrs : { a | query : QueryDict, route : Route } -> Route -> List (H.Attribute msg)
linkAttrs { query, route } target =
    [ linkClass route target, Route.href query target ]


linkClass : Route -> Route -> H.Attribute msg
linkClass active target =
    class <|
        if target == active then
            "active button disabled"

        else
            "inactive button"
