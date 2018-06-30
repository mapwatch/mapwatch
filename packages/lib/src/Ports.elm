port module Ports
    exposing
        ( inputClientLogWithId
        , logline
        , Progress
        , progress
        , progressComplete
        , sendJoinInstance
        )

import Time as Time exposing (Time)
import Date as Date exposing (Date)
import Maybe.Extra
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Visit as Visit exposing (Visit)
import Mapwatch.Run as Run exposing (Run)
import Json.Encode as Encode
import Json.Decode as Decode


port inputClientLogWithId : { id : String, maxSize : Int } -> Cmd msg


port logline : (String -> msg) -> Sub msg


type alias Progress =
    { val : Int, max : Int, startedAt : Time, updatedAt : Time, name : String }


port progress : (Progress -> msg) -> Sub msg


type alias InstanceEvent =
    Maybe Instance.Address


type alias VisitEvent =
    { instance : InstanceEvent, joinedAt : Time, leftAt : Time }


type alias RunEvent =
    { instance : Instance.Address, joinedAt : Time, leftAt : Time }



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


sendJoinInstance : Date -> Instance -> Maybe Visit -> Maybe Run -> Cmd msg
sendJoinInstance date instance visit run =
    events <|
        Encode.object
            [ ( "type", Encode.string "joinInstance" )
            , ( "joinedAt", encodeDate date )
            , ( "instance", encodeInstance instance )
            , ( "lastVisit", Maybe.Extra.unwrap Encode.null encodeVisit visit )
            , ( "lastMapRun", Maybe.Extra.unwrap Encode.null encodeMapRun run )
            , ( "say", Maybe.Extra.unwrap Encode.null (Encode.string << sayMapRun) run )
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


sayMapRun : Run -> String
sayMapRun r =
    let
        dur =
            floor <| Run.duration r

        m =
            abs <| rem dur (truncate Time.hour) // (truncate Time.minute)

        s =
            abs <| rem dur (truncate Time.minute) // (truncate Time.second)
    in
        (Run.instance r).zone ++ " finished in " ++ toString m ++ "min " ++ toString s ++ "sec"


encodeDate : Date -> Encode.Value
encodeDate =
    Date.toTime >> Encode.float
