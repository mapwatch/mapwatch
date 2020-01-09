module Mapwatch.Debug exposing (log)


log : String -> a -> a
log msg =
    -- Debug.log
    identity
