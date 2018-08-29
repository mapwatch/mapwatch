module Main exposing (main)

import Mapwatch exposing (init, subscriptions, update)
import Platform


main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
