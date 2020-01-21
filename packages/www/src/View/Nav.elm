module View.Nav exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import View.Icon as Icon


view : { a | query : QueryDict, route : Route } -> Html msg
view ({ query, route } as model) =
    nav []
        [ a (linkAttrs model Route.Timer) [ Icon.fas "stopwatch", text " Timer" ]
        , a (linkAttrs model Route.History) [ Icon.fas "history", text " History" ]
        , a (linkAttrs model Route.Maps) [ Icon.fas "map", text " Maps" ]
        , a (linkAttrs model Route.Changelog) [ Icon.fas "newspaper", text " Changes" ]
        , a (linkAttrs model Route.Settings) [ Icon.fas "cog", text " Settings" ]
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
