module Main exposing (main)

import Browser
import Model exposing (init, subscriptions, update)
import View.View exposing (view)


main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlRequest = Model.NavRequest
        , onUrlChange = Model.NavLocation
        }
