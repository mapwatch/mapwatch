module Model.Visit
    exposing
        ( Visit
        , tryInit
        , initSince
          -- selectors
        , duration
        , isTown
        , isMap
        , isOffline
        )

import Date
import Time
import Model.Instance as Instance exposing (Instance)


type alias Visit =
    { instance : Maybe Instance, joinedAt : Date.Date, leftAt : Date.Date }


duration : Visit -> Time.Time
duration v =
    max 0 <| Date.toTime v.leftAt - Date.toTime v.joinedAt


isTown : Visit -> Bool
isTown =
    Instance.isTown << .instance


isMap : Visit -> Bool
isMap =
    Instance.isMap << .instance


isOffline : Visit -> Bool
isOffline v =
    Instance.isDurationOffline <| duration v


initSince : Instance.State -> Date.Date -> Visit
initSince before leftAt =
    case before.joinedAt of
        Nothing ->
            Debug.crash <| "Visit.initSince: joinedAt should always be defined, but it's not." ++ toString { before = before, leftAt = leftAt }

        Just joinedAt ->
            { instance = before.val, joinedAt = joinedAt, leftAt = leftAt }


tryInit : Instance.State -> Instance.State -> Maybe Visit
tryInit before after =
    if before.val == after.val && before.joinedAt == after.joinedAt then
        Nothing
    else
        case after.joinedAt of
            Nothing ->
                Debug.crash <| "Visit.tryInit: leftAt should always be defined, but it's not." ++ toString { before = before, after = after }

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
