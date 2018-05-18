module Main exposing (main)

import Html as H
import View exposing (view)
import Model exposing (init, update, subscriptions)


main =
    H.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
