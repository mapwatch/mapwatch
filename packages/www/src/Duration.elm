module Duration exposing (Millis, diff, hour, minute, second)

import Time exposing (Posix)


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


diff : { before : Posix, after : Posix } -> Millis
diff { before, after } =
    Time.posixToMillis after - Time.posixToMillis before
