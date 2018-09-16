module Main exposing (main)

import Browser
import Model exposing (Msg(..), init, subscriptions, update)
import View.View exposing (view)


main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view

        -- clicking a link
        , onUrlRequest = NavRequest

        -- altering the address bar, or other url changes
        , onUrlChange = NavLocation
        }
