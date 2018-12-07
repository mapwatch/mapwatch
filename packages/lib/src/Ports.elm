port module Ports exposing
    ( Progress
    , changelog
    , inputClientLogWithId
    , logline
    , progress
    , progressComplete
    , sendJoinInstance
    , sendVolume
    )

import Duration exposing (Millis)
import Json.Decode as Decode
import Json.Encode as Encode
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Run as Run exposing (Run)
import Mapwatch.Visit as Visit exposing (Visit)
import Maybe.Extra
import Speech
import Time


port inputClientLogWithId : { id : String, maxSize : Int } -> Cmd msg


port changelog : (String -> msg) -> Sub msg


{-| date is included in the line itself, but elm has trouble parsing it with the
new 0.19 time api. I'm sure someone will come up with a library soon enough,
but for now, let js do it.
-}
port logline : ({ line : String, date : Int } -> msg) -> Sub msg


type alias Progress =
    { val : Int
    , max : Int
    , startedAt : Int
    , updatedAt : Int
    , name : String
    }


port progress : (Progress -> msg) -> Sub msg


type alias InstanceEvent =
    Maybe Instance.Address


type alias VisitEvent =
    { instance : InstanceEvent
    , joinedAt : Time.Posix
    , leftAt : Time.Posix
    }


type alias RunEvent =
    { instance : Instance.Address
    , joinedAt : Time.Posix
    , leftAt : Time.Posix
    }



-- not used internally; these are for callers and analytics.
-- These really should be two separate ports, but using the same outgoing port guarantees order, and that's important.


port events : Encode.Value -> Cmd msg


progressComplete : { name : String } -> Cmd msg
progressComplete e =
    events <|
        Encode.object
            [ ( "type", Encode.string "progressComplete" )
            , ( "name", Encode.string e.name )
            ]


sendJoinInstance : Time.Posix -> Instance -> Maybe Visit -> Run.State -> Maybe Run -> Cmd msg
sendJoinInstance date instance visit runState lastRun =
    events <|
        Encode.object
            [ ( "type", Encode.string "joinInstance" )
            , ( "joinedAt", encodeDate date )
            , ( "instance", encodeInstance instance )
            , ( "lastVisit", visit |> Maybe.Extra.unwrap Encode.null encodeVisit )
            , ( "lastMapRun", lastRun |> Maybe.Extra.unwrap Encode.null encodeMapRun )
            , ( "say", Speech.joinInstance runState lastRun instance |> Maybe.Extra.unwrap Encode.null Encode.string )
            ]


sendVolume : Int -> Cmd msg
sendVolume volume =
    events <|
        Encode.object
            [ ( "type", Encode.string "volume" )
            , ( "volume", toFloat volume / 100 |> Encode.float )
            ]


encodeAddress : Instance.Address -> Encode.Value
encodeAddress i =
    Encode.object [ ( "zone", Encode.string i.zone ), ( "addr", Encode.string i.addr ) ]


encodeInstance : Instance -> Encode.Value
encodeInstance =
    Instance.unwrap Encode.null encodeAddress


encodeVisit : Visit -> Encode.Value
encodeVisit v =
    Encode.object
        [ ( "instance", encodeInstance v.instance )
        , ( "joinedAt", encodeDate v.joinedAt )
        , ( "leftAt", encodeDate v.leftAt )
        ]


encodeMapRun : Run -> Encode.Value
encodeMapRun r =
    Encode.object
        [ ( "instance", encodeAddress <| Run.instance r )
        , ( "joinedAt", encodeDate r.first.joinedAt )
        , ( "leftAt", encodeDate r.last.leftAt )
        ]


encodeDate : Time.Posix -> Encode.Value
encodeDate =
    Time.posixToMillis >> Encode.int
