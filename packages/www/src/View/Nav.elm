module View.Nav exposing (view)

import Html as H exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Route exposing (Route)
import Route.QueryDict exposing (QueryDict)
import View.Icon as Icon


view : { a | query : QueryDict, route : Route } -> Html msg
view model =
    nav []
        [ a (linkAttrs model Route.Timer) [ Icon.fas "stopwatch", text " ", span [ L.navTimer ] [] ]
        , a (linkAttrs model Route.History) [ Icon.fas "history", text " ", span [ L.navHistory ] [] ]
        , a (linkAttrs model Route.Maps) [ Icon.fas "map", text " ", span [ L.navMaps ] [] ]
        , a (linkAttrs model Route.Encounters) [ Icon.fas "directions", text " ", span [ L.navEncounters ] [] ]
        , a (linkAttrs model Route.Changelog) [ Icon.fas "newspaper", text " ", span [ L.navChangelog ] [] ]
        , a (linkAttrs model Route.Settings) [ Icon.fas "cog", text " ", span [ L.navSettings ] [] ]
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
