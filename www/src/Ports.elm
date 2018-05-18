port module Ports exposing (..)


type alias Config =
    { wshost : String
    , clientLogPath : String
    }


port startWatching : Config -> Cmd msg


port inputClientLog : String -> Cmd msg


port logline : (String -> msg) -> Sub msg
