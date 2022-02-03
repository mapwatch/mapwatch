module TimedReadline exposing
    ( Progress
    , TimedReadline
    , create
    , durationMillis
    , progress
    , read
    , resize
    )

import Readline exposing (Readline)
import Time exposing (Posix)


type alias TimedReadline =
    { val : Readline
    , startedAt : Posix
    , updatedAt : Posix
    }


create : { start : Int, end : Int, now : Posix } -> TimedReadline
create args =
    { val = Readline.create { start = args.start, end = args.end }
    , startedAt = args.now
    , updatedAt = args.now
    }


read : Posix -> Int -> String -> TimedReadline -> ( List ( Int, String ), TimedReadline )
read now pos chunk r =
    Readline.read pos chunk r.val
        |> Tuple.mapSecond (\val -> { r | val = val, updatedAt = now })


resize : Posix -> Int -> TimedReadline -> Result String TimedReadline
resize now end r0 =
    Result.map
        (\val ->
            let
                r =
                    { r0 | val = val, updatedAt = now }
            in
            if r.val.start /= val.start then
                { r | startedAt = now }

            else
                r
        )
        (Readline.resize end r0.val)


durationMillis : TimedReadline -> Int
durationMillis r =
    Time.posixToMillis r.updatedAt - Time.posixToMillis r.startedAt


type alias Progress =
    { percent : Float
    , max : Int
    , value : Int
    , isDone : Bool
    , durationMillis : Int
    }


progress : TimedReadline -> Progress
progress r =
    let
        p =
            Readline.progress r.val
    in
    { durationMillis = durationMillis r
    , percent = p.percent
    , max = p.max
    , value = p.value
    , isDone = p.isDone
    }
