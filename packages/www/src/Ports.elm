port module Ports exposing (..)

import Time as Time exposing (Time)
import Model.Instance as Instance exposing (Instance)


port inputClientLogWithId : { id : String, maxSize : Int } -> Cmd msg


port logline : (String -> msg) -> Sub msg


type alias Progress =
    { val : Int, max : Int, startedAt : Time, updatedAt : Time }


port progress : (Progress -> msg) -> Sub msg



-- the Mapwatch website doesn't use mapRunEvent for anything internally.
-- It's for use as a library, by callers.


port mapRunEvent : { startedAt : Time, finishedAt : Time, instance : Instance } -> Cmd msg
