module Main exposing (main)

import View.View exposing (view)
import Model exposing (init, update, subscriptions)
import Navigation


main =
    Navigation.programWithFlags Model.Navigate
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
