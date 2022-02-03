module Mapwatch.Visit exposing
    ( Visit
    , duration
    , durationAfk
    , durationMinusAfk
    ,  initSince
       -- selectors

    , isMap
    , isOffline
    , isTown
    , tryInit
    )

import Duration exposing (Millis)
import Mapwatch.Instance as Instance exposing (Instance)
import Time exposing (Posix)


type alias Visit =
    { instance : Instance
    , joinedAt : Posix
    , leftAt : Posix
    , afk : List ( Posix, Posix )
    , positionStart : Int
    , positionEnd : Int
    }


duration : Visit -> Millis
duration v =
    Time.posixToMillis v.leftAt - Time.posixToMillis v.joinedAt |> max 0


durationAfk : Visit -> Millis
durationAfk v =
    v.afk
        |> List.map (\( start, end ) -> Time.posixToMillis end - Time.posixToMillis start |> abs)
        |> List.sum
        |> max 0


durationMinusAfk : Visit -> Millis
durationMinusAfk v =
    duration v - durationAfk v |> max 0


isTown : Visit -> Bool
isTown =
    Instance.isTown << .instance


isMap : Visit -> Bool
isMap =
    Instance.isMap << .instance


isOffline : Visit -> Bool
isOffline v =
    Instance.isDurationOffline (duration v) v.instance


initSince : Instance.State -> Posix -> Int -> Int -> Visit
initSince before leftAt posStart posEnd =
    { instance = before.val
    , joinedAt = before.joinedAt
    , leftAt = leftAt
    , positionStart = posStart
    , positionEnd = posEnd
    , afk = (Instance.afkOff leftAt before).afkVisit
    }


tryInit : Maybe Instance.State -> Instance.State -> Int -> Maybe Visit
tryInit mbefore after posEnd =
    case mbefore of
        Nothing ->
            Nothing

        Just before ->
            if before.val == after.val && before.joinedAt == after.joinedAt then
                Nothing

            else
                let
                    leftAt =
                        after.joinedAt
                in
                Just
                    { instance = before.val
                    , joinedAt = before.joinedAt
                    , leftAt = leftAt
                    , positionStart = before.position
                    , positionEnd = posEnd
                    , afk = (Instance.afkOff leftAt before).afkVisit
                    }
