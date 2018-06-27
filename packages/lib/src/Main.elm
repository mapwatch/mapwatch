module Main exposing (main)

import Platform
import Mapwatch exposing (init, update, subscriptions)


main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
