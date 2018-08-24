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
import Time


type alias Visit =
    { instance : Instance, joinedAt : Time.Posix, leftAt : Time.Posix }


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
    Instance.isDurationOffline <| duration v


initSince : Instance.State -> Time.Posix -> Visit
initSince before leftAt =
    case before.joinedAt of
        Nothing ->
            Debug.todo <| "Visit.initSince: joinedAt should always be defined, but it's not." ++ Debug.toString { before = before, leftAt = leftAt }

        Just joinedAt ->
            { instance = before.val, joinedAt = joinedAt, leftAt = leftAt }


tryInit : Instance.State -> Instance.State -> Maybe Visit
tryInit before after =
    if before.val == after.val && before.joinedAt == after.joinedAt then
        Nothing

    else
        case after.joinedAt of
            Nothing ->
                Debug.todo <| "Visit.tryInit: leftAt should always be defined, but it's not." ++ Debug.toString { before = before, after = after }

            Just leftAt ->
                -- With no log-lines processed, the first instance has no joinedAt.
                -- Don't create a Visit for that one.
                before.joinedAt
                    |> Maybe.map
                        (\joinedAt ->
                            { instance = before.val
                            , joinedAt = joinedAt
                            , leftAt = leftAt
                            }
                        )
