module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    )

import Json.Decode as Json
import Request exposing (Request)


type alias Flags =
    { loadedAt : Int
    , tickOffset : Int
    , isBrowserSupported : Bool
    , platform : String
    , changelog : String
    , privacy : String
    , version : String
    , datamine : Json.Value
    , logtz : Maybe Float
    , settings : Json.Value
    , electronFlags : Maybe { version : String }
    }


type alias Model =
    { flags : Flags }


type Msg
    = NoOp


init : Request -> Flags -> ( Model, Cmd Msg )
init _ flags =
    ( { flags = flags }, Cmd.none )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
