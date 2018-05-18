port module Ports exposing (..)


port inputClientLogWithId : String -> Cmd msg


port logline : (String -> msg) -> Sub msg
