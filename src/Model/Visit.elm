module Model.Visit
    exposing
        ( Visit
        , tryInit
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
    Date.toTime v.leftAt - Date.toTime v.joinedAt


isTown : Visit -> Bool
isTown =
    Instance.isTown << .instance


isMap : Visit -> Bool
isMap =
    Instance.isMap << .instance


isOffline : Visit -> Bool
isOffline v =
    -- TODO threshold should be configurable
    duration v > 20 * Time.minute


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
