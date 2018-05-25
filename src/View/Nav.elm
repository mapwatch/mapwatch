module View.Nav exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..), HistoryParams, MapsParams, timerParams0, historyParams0, mapsParams0)
import View.Icon as Icon
import Date as Date exposing (Date)


view : Maybe Route -> H.Html msg
view active =
    H.nav []
        [ timerLink active
        , historyLink active
        , mapsLink active
        , changelogLink active
        , sourceLink
        ]


inactiveCls =
    A.class "inactive button"


activeCls =
    A.class "active button disabled"


timerLink : Maybe Route -> H.Html msg
timerLink active =
    let
        ( cls, qs ) =
            case active of
                Just (Timer qs) ->
                    ( activeCls, qs )

                Just (History qs) ->
                    ( inactiveCls, { timerParams0 | after = qs.after } )

                Just (Maps qs) ->
                    ( inactiveCls, { timerParams0 | after = qs.after } )

                _ ->
                    ( inactiveCls, { timerParams0 | after = Nothing } )
    in
        H.a [ cls, Route.href <| Timer qs ] [ Icon.fas "stopwatch", H.text " Timer" ]


historyLink : Maybe Route -> H.Html msg
historyLink active =
    let
        qs0 =
            Route.HistoryParams 0 Nothing Nothing Nothing Nothing

        ( cls, qs ) =
            case active of
                Just (History qs) ->
                    ( activeCls, qs )

                Just (Timer qs) ->
                    ( inactiveCls, { qs0 | after = qs.after } )

                Just (Maps qs) ->
                    ( inactiveCls, { qs0 | search = qs.search, after = qs.after, before = qs.before } )

                _ ->
                    ( inactiveCls, qs0 )
    in
        H.a [ cls, Route.href <| History qs ] [ Icon.fas "history", H.text " History" ]


mapsLink : Maybe Route -> H.Html msg
mapsLink active =
    let
        qs0 =
            Route.MapsParams Nothing Nothing Nothing

        ( cls, qs ) =
            case active of
                Just (Maps qs) ->
                    ( activeCls, qs )

                Just (History qs) ->
                    ( inactiveCls, { qs0 | search = qs.search, after = qs.after, before = qs.before } )

                Just (Timer qs) ->
                    ( inactiveCls, { qs0 | after = qs.after } )

                _ ->
                    ( inactiveCls, qs0 )
    in
        H.a [ cls, Route.href <| Maps qs ] [ Icon.fas "map", H.text " Maps" ]


changelogLink active =
    let
        cls =
            case active of
                Just Changelog ->
                    activeCls

                _ ->
                    inactiveCls
    in
        H.a [ cls, Route.href <| Changelog ] [ Icon.fas "newspaper", H.text " Changes" ]


sourceLink =
    H.a [ A.target "_blank", A.href "https://www.github.com/mapwatch/mapwatch", inactiveCls ]
        [ Icon.fas "code", H.text " Code" ]
