module Localized exposing
    ( Bundle, provider
    , ArgValue, int, float, bool, null, string, maybe, unsafeString
    , text, text0, element, node
    )

{-| Elm localization with <https://projectfluent.org> and @wolfadex/fluent-web


# Provider

@docs Bundle, provider


# Args

@docs ArgValue, int, float, bool, null, string, maybe, unsafeString


# Nodes

@docs text, text0, element, node

-}

import Html as H exposing (Html)
import Html.Attributes as A
import Json.Encode as Json



-- provider


type alias Bundle =
    Json.Value


provider : List Bundle -> List (Html msg) -> Html msg
provider bundles =
    H.node "fluent-provider"
        [ A.property "bundles" <| Json.list identity bundles
        ]



-- args


type alias Arg =
    ( String, ArgValue )


type ArgValue
    = SafeArg Json.Value
    | UnsafeArg String


safeArg : (a -> Json.Value) -> String -> a -> Arg
safeArg encoder name val =
    ( name, SafeArg <| encoder val )


int : String -> Int -> Arg
int =
    safeArg Json.int


float : String -> Float -> Arg
float =
    safeArg Json.float


bool : String -> Bool -> Arg
bool =
    safeArg Json.bool


string : String -> String -> Arg
string =
    safeArg Json.string


null : String -> Arg
null name =
    ( name, SafeArg Json.null )


maybe : (String -> a -> Arg) -> String -> Maybe a -> Arg
maybe encoder name mval =
    case mval of
        Nothing ->
            null name

        Just val ->
            encoder name val


unsafeString : String -> String -> Arg
unsafeString name val =
    ( name, UnsafeArg val )



-- arg encoding


partitionArgs : List Arg -> ( List ( String, Json.Value ), List ( String, Json.Value ) )
partitionArgs =
    let
        loop :
            ( List ( String, Json.Value ), List ( String, Json.Value ) )
            -> List Arg
            -> ( List ( String, Json.Value ), List ( String, Json.Value ) )
        loop (( safes, unsafes ) as accum) args =
            case args of
                [] ->
                    accum

                ( name, head ) :: tail ->
                    case head of
                        SafeArg safe ->
                            loop ( ( name, safe ) :: safes, unsafes ) tail

                        UnsafeArg unsafe ->
                            loop ( safes, ( name, Json.string unsafe ) :: unsafes ) tail
    in
    loop ( [], [] )


argAttributes : ( List ( String, Json.Value ), List ( String, Json.Value ) ) -> List (H.Attribute msg)
argAttributes ( safes, unsafes ) =
    List.filterMap identity
        [ case safes of
            [] ->
                Nothing

            _ ->
                safes
                    |> Json.object
                    |> A.property "args"
                    |> Just
        , case unsafes of
            [] ->
                Nothing

            _ ->
                unsafes
                    |> Json.object
                    |> A.property "unsafeArgs"
                    |> Just
        ]


encodeArgs : List Arg -> List (H.Attribute msg)
encodeArgs =
    partitionArgs >> argAttributes



-- nodes


text : String -> List Arg -> Html msg
text id_ args =
    H.node "fluent-text"
        (A.attribute "messageId" id_ :: encodeArgs args)
        []


{-| A text argument with zero args. very common
-}
text0 : String -> Html msg
text0 id_ =
    text id_ []


element : String -> List String -> List Arg -> Html msg -> Html msg
element id_ attrs args el =
    H.node "fluent-element"
        ([ A.attribute "messageId" id_
         , A.property "whitelist" <| Json.list Json.string attrs
         ]
            ++ encodeArgs args
        )
        [ el ]


node : String -> List String -> List Arg -> Html msg
node id_ attrs args =
    element id_ attrs args (H.div [] [])
