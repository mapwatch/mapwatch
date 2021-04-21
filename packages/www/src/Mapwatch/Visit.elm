module Mapwatch.Visit exposing
    ( Visit
    , duration
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
    , positionStart : Int
    , positionEnd : Int
    }


duration : Visit -> Millis
duration v =
    max 0 <| Time.posixToMillis v.leftAt - Time.posixToMillis v.joinedAt


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
    { instance = before.val, joinedAt = before.joinedAt, leftAt = leftAt, positionStart = posStart, positionEnd = posEnd }


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
                    }
