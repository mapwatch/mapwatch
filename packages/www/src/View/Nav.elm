module View.Nav exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route as Route exposing (HistoryParams, MapsParams, Route(..), historyParams0, mapsParams0, timerParams0)
import View.Icon as Icon


view : Maybe Route -> Html msg
view active =
    nav []
        [ timerLink active
        , historyLink active
        , mapsLink active
        , changelogLink active
        , sourceLink
        ]


inactiveCls =
    class "inactive button"


activeCls =
    class "active button disabled"


timerLink : Maybe Route -> Html msg
timerLink active =
    let
        ( cls, qs ) =
            case active of
                Just (Timer qs_) ->
                    ( activeCls, qs_ )

                Just (History qs_) ->
                    ( inactiveCls, { timerParams0 | after = qs_.after, goal = qs_.goal } )

                Just (Maps qs_) ->
                    ( inactiveCls, { timerParams0 | after = qs_.after } )

                _ ->
                    ( inactiveCls, { timerParams0 | after = Nothing } )
    in
    a [ cls, Route.href <| Timer qs ] [ Icon.fas "stopwatch", text " Timer" ]


historyLink : Maybe Route -> Html msg
historyLink active =
    let
        qs0 =
            Route.historyParams0

        ( cls, qs ) =
            case active of
                Just (History qs_) ->
                    ( activeCls, qs_ )

                Just (Timer qs_) ->
                    ( inactiveCls, { qs0 | after = qs_.after, goal = qs_.goal } )

                Just (Maps qs_) ->
                    ( inactiveCls, { qs0 | search = qs_.search, after = qs_.after, before = qs_.before } )

                _ ->
                    ( inactiveCls, qs0 )
    in
    a [ cls, Route.href <| History qs ] [ Icon.fas "history", text " History" ]


mapsLink : Maybe Route -> Html msg
mapsLink active =
    let
        qs0 =
            Route.mapsParams0

        ( cls, qs ) =
            case active of
                Just (Maps qs_) ->
                    ( activeCls, qs_ )

                Just (History qs_) ->
                    ( inactiveCls, { qs0 | search = qs_.search, after = qs_.after, before = qs_.before } )

                Just (Timer qs_) ->
                    ( inactiveCls, { qs0 | after = qs_.after } )

                _ ->
                    ( inactiveCls, qs0 )
    in
    a [ cls, Route.href <| Maps qs ] [ Icon.fas "map", text " Maps" ]


changelogLink active =
    let
        cls =
            case active of
                Just Changelog ->
                    activeCls

                _ ->
                    inactiveCls
    in
    a [ cls, Route.href <| Changelog ] [ Icon.fas "newspaper", text " Changes" ]


sourceLink =
    a [ target "_blank", href "https://www.github.com/mapwatch/mapwatch", inactiveCls ]
        [ Icon.fas "code", text " Code" ]
