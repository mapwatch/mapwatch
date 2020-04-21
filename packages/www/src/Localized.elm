module Localized exposing (..)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Model exposing (OkModel)
import Time exposing (Posix)


type alias Messages =
    Json.Value


bundles : OkModel -> Json.Value
bundles model =
    let
        defaultLocales =
            model.flags.messages.defaultLocales

        selectedLocales =
            List.filterMap identity [ model.settings.locale ]
                ++ defaultLocales

        selectedBundles : List Messages
        selectedBundles =
            selectedLocales
                |> List.filterMap (\l -> Dict.get l model.bundles)
    in
    Json.list identity selectedBundles


joinName : List String -> String
joinName =
    String.join "-"



-- nodes


provider : Maybe Messages -> List (Html msg) -> Html msg
provider msgs =
    H.node "fluent-provider"
        [ A.property "bundles" <| Maybe.withDefault Json.null msgs
        ]


text : String -> List ( String, Json.Value ) -> Html msg
text id_ args =
    H.node "fluent-text"
        [ A.attribute "messageId" id_
        , A.property "args" <| Json.object args
        ]
        []


{-| A text argument with zero args. very common
-}
text0 : String -> Html msg
text0 id_ =
    text id_ []


element : String -> List String -> List ( String, Json.Value ) -> Html msg -> Html msg
element id_ attrs args el =
    H.node "fluent-element"
        [ A.attribute "messageId" id_
        , A.property "whitelist" <| Json.list Json.string attrs
        , A.property "args" <| Json.object args
        ]
        [ el ]


node : String -> List String -> List ( String, Json.Value ) -> Html msg
node id_ attrs args =
    element id_ attrs args (div [] [])



-- nicely-typed messages


hello : Html msg
hello =
    node "hello" [ "title" ] []


{-| Undefined message, used for testing
-}
messageNotFoundDebug : Html msg
messageNotFoundDebug =
    text "message-not-found-DEBUG" []


title : Html msg
title =
    text "title" []


subtitle : Html msg
subtitle =
    text "subtitle" []
