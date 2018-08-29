module Main exposing (main)

import Model exposing (init, subscriptions, update)
import Navigation
import View.View exposing (view)


main =
    Navigation.programWithFlags Model.Navigate
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
