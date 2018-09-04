module Mapwatch.Instance exposing
    ( Address
    , Builder(..)
    , Instance(..)
    , State
    , duration
    , init
    , isDurationOffline
    , isMap
    , isOffline
    , isTown
    , offlineThreshold
    , unsafeJoinedAt
    , unwrap
    , update
    , zone
    )

import Duration exposing (Millis)
import Mapwatch.LogLine as LogLine
import Mapwatch.Zone as Zone
import Maybe.Extra
import Time



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
    , joinedAt : Maybe Time.Posix -- Nothing if no loglines have been processed yet
    , next : Builder
    }


init : State
init =
    -- initial-date is awkward, only Nothing on init, but we need to be able to tell the difference
    { val = MainMenu, joinedAt = Nothing, next = Empty }


unsafeJoinedAt : State -> Time.Posix
unsafeJoinedAt { joinedAt } =
    case joinedAt of
        Nothing ->
            Debug.todo "instance.unsafeJoinedAt" joinedAt

        Just d ->
            d


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


duration : Time.Posix -> State -> Maybe Millis
duration now state =
    Maybe.map (\at -> Time.posixToMillis now - Time.posixToMillis at) state.joinedAt


offlineThreshold : Millis
offlineThreshold =
    -- TODO threshold should be configurable
    30 * Duration.minute


isDurationOffline : Millis -> Bool
isDurationOffline dur =
    dur >= offlineThreshold


isOffline : Time.Posix -> State -> Bool
isOffline now instance =
    isDurationOffline <| Maybe.withDefault 0 <| duration now instance


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
            { val = Instance { zone = zone_, addr = addr }, joinedAt = Just line.date, next = Empty }

        ( Connecting _, LogLine.ConnectingToInstanceServer addr ) ->
            -- two "connecting" messages - should never happen, but trust the most recent one
            { state | next = Connecting addr }

        ( _, LogLine.Opening ) ->
            -- the game crashed and was just reopened, reset the instance
            { init | joinedAt = Just line.date }

        _ ->
            -- ignore everything else
            state
