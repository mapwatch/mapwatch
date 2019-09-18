module Mapwatch.Instance exposing
    ( Address
    , Builder(..)
    , Instance(..)
    , State
    , duration
    , init
    , initOrUpdate
    , isDurationOffline
    , isMap
    , isOffline
    , isTown
    , offlineThreshold
    , unwrap
    , update
    , zone
    )

import Duration exposing (Millis)
import Mapwatch.LogLine as LogLine
import Mapwatch.Zone as Zone
import Maybe.Extra
import Time exposing (Posix)



-- (Zone, instance-server-address) isn't really a unique id -
-- imagine running two Volcano maps that just so happen to be assigned to the
-- same instance server. It's the best we've got, though.


type alias Address =
    { zone : String, addr : String }


type Instance
    = MainMenu
    | Instance Address


type Builder
    = Empty
    | Connecting String


type alias State =
    { val : Instance
    , joinedAt : Time.Posix
    , next : Builder
    }


init : Posix -> State
init t =
    -- initial-date is awkward, only Nothing on init, but we need to be able to tell the difference
    { val = MainMenu, joinedAt = t, next = Empty }


unwrap : a -> (Address -> a) -> Instance -> a
unwrap default fn instance0 =
    case instance0 of
        MainMenu ->
            default

        Instance instance ->
            fn instance


zone : Instance -> Maybe String
zone =
    unwrap Nothing (Just << .zone)


isTown : Instance -> Bool
isTown =
    -- No-zone counts as town, since you log back in to town
    unwrap True (Zone.isTown << .zone)


isMap : Instance -> Bool
isMap =
    unwrap False (Zone.isMap << .zone)


duration : Time.Posix -> State -> Millis
duration now state =
    Time.posixToMillis now - Time.posixToMillis state.joinedAt


offlineThreshold : Millis
offlineThreshold =
    -- TODO threshold should be configurable
    30 * Duration.minute


isDurationOffline : Millis -> Bool
isDurationOffline dur =
    dur >= offlineThreshold


isOffline : Time.Posix -> State -> Bool
isOffline now instance =
    isDurationOffline <| duration now instance


initOrUpdate : LogLine.Line -> Maybe State -> State
initOrUpdate line instance =
    case instance of
        Just i ->
            update line i

        Nothing ->
            init line.date |> update line


update : LogLine.Line -> State -> State
update line state =
    case ( state.next, line.info ) of
        -- it takes two loglines to build an instance:
        -- * "connecting to instance server (addr)"
        -- * "you have entered (zone)"
        -- we need both zone and addr, split across two lines, so it takes two steps.
        ( Empty, LogLine.ConnectingToInstanceServer addr ) ->
            -- step 1
            { state | next = Connecting addr }

        ( Connecting addr, LogLine.YouHaveEntered zone_ ) ->
            -- step 2
            { val = Instance { zone = zone_, addr = addr }, joinedAt = line.date, next = Empty }

        ( Connecting _, LogLine.ConnectingToInstanceServer addr ) ->
            -- two "connecting" messages - should never happen, but trust the most recent one
            { state | next = Connecting addr }

        ( _, LogLine.Opening ) ->
            -- the game crashed and was just reopened, reset the instance
            init line.date

        _ ->
            -- ignore everything else
            state
