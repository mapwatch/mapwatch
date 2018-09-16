port module NavPorts exposing (onUrlChange, pushUrl, replaceUrl)


port onUrlChange : (String -> msg) -> Sub msg


port pushUrl : String -> Cmd msg


port replaceUrl : String -> Cmd msg
