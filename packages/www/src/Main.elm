module Main exposing (main)

import View.View exposing (view)
import Mapwatch exposing (init, update, subscriptions)
import Navigation


main =
    Navigation.programWithFlags Mapwatch.Navigate
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
