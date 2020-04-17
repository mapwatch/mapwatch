port module Ports exposing
    ( Progress
    , Sheet
    , debugNotification
    , fileSelector
    , gsheetsDisconnect
    , gsheetsLogin
    , gsheetsLoginUpdate
    , gsheetsLogout
    , gsheetsWrite
    , gsheetsWritten
    , logChanged
    , logOpened
    , logSelected
    , logSlice
    , logSliceReq
    , logline
    , progress
    , progressComplete
    , sendJoinInstance
    , sendSettings
    )

import Duration exposing (Millis)
import Json.Decode as Decode
import Json.Encode as Encode
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.Visit as Visit exposing (Visit)
import Maybe.Extra
import Settings exposing (Settings)
import Speech exposing (Speech)
import Time exposing (Posix)


port fileSelector : { maxSize : Int } -> Cmd msg


{-| The user chose a file with the file selector on the front page.
-}
port logSelected : { id : String, maxSize : Int } -> Cmd msg


{-| date is included in the line itself, but elm has trouble parsing it with the
new 0.19 time api. I'm sure someone will come up with a library soon enough,
but for now, let js do it.

TODO remove me, this was for old js log splitting

-}
port logline : ({ line : String, date : Int } -> msg) -> Sub msg


{-| Our JS backend opened a log file and reported its size
-}
port logOpened : ({ size : Int, date : Int } -> msg) -> Sub msg


{-| Our JS backend detected a change in log file size
-}
port logChanged : ({ size : Int, oldSize : Int, date : Int } -> msg) -> Sub msg


{-| We're done processing a chunk of logs - ask for more
-}
port logSliceReq : { position : Int, length : Int } -> Cmd msg


{-| Our JS backend sent us a chunk of text from the logfile

Usually a response to a logSliceReq

-}
port logSlice : ({ position : Int, length : Int, value : String, date : Int } -> msg) -> Sub msg


type alias Progress =
    { val : Int
    , max : Int
    , startedAt : Int
    , updatedAt : Int
    , name : String
    }


port progress : (Progress -> msg) -> Sub msg


type alias InstanceEvent =
    Maybe Instance.Address


type alias VisitEvent =
    { instance : InstanceEvent
    , joinedAt : Posix
    , leftAt : Posix
    }


type alias RunEvent =
    { instance : Instance.Address
    , joinedAt : Posix
    , leftAt : Posix
    }



-- not used internally; these are for callers and analytics.
-- These really should be two separate ports, but using the same outgoing port guarantees order, and that's important.


port events : Encode.Value -> Cmd msg


progressComplete : Settings -> { name : String } -> Cmd msg
progressComplete settings e =
    events <|
        Encode.object
            [ ( "type", Encode.string "progressComplete" )
            , ( "name", Encode.string e.name )
            , ( "say", Speech.progressComplete settings e.name |> Maybe.Extra.unwrap Encode.null Speech.encoder )
            ]


sendJoinInstance : Settings -> Bool -> Posix -> Instance -> Maybe Visit -> RawMapRun.State -> Maybe MapRun -> Cmd msg
sendJoinInstance settings isHistoryDone date instance visit runState lastRun =
    events <|
        Encode.object
            [ ( "type", Encode.string "joinInstance" )
            , ( "joinedAt", encodeDate date )
            , ( "instance", encodeInstance instance )
            , ( "lastVisit", visit |> Maybe.Extra.unwrap Encode.null encodeVisit )
            , ( "lastMapRun", lastRun |> Maybe.Extra.unwrap Encode.null encodeMapRun )
            , ( "say", Speech.joinInstance settings isHistoryDone runState lastRun |> Maybe.Extra.unwrap Encode.null Speech.encoder )
            ]


port sendSettings : Settings -> Cmd msg


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


encodeMapRun : MapRun -> Encode.Value
encodeMapRun r =
    Encode.object
        [ ( "instance", encodeAddress r.address )
        , ( "joinedAt", encodeDate r.startedAt )
        , ( "leftAt", encodeDate r.updatedAt )
        ]


encodeDate : Posix -> Encode.Value
encodeDate =
    Time.posixToMillis >> Encode.int


port gsheetsLogin : () -> Cmd msg


port gsheetsLoginUpdate : ({ login : Maybe Bool, error : Maybe String } -> msg) -> Sub msg


port gsheetsLogout : () -> Cmd msg


port gsheetsDisconnect : () -> Cmd msg


type alias Sheet =
    { title : String
    , headers : List (List String)
    , rows : List (List Decode.Value)
    }


port gsheetsWrite :
    { spreadsheetId : Maybe String
    , title : String
    , content : List Sheet
    }
    -> Cmd msg


port gsheetsWritten :
    ({ res : Maybe { spreadsheetId : String, spreadsheetUrl : String }
     , error : Maybe String
     }
     -> msg
    )
    -> Sub msg


port debugNotification : Decode.Value -> Cmd msg
