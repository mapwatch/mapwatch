module Duration exposing (Millis, hour, minute, second)


type alias Millis =
    Int


second : Millis
second =
    1000


minute : Millis
minute =
    second * 60


hour : Millis
hour =
    minute * 60
