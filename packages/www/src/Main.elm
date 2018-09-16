module Main exposing (main)

import Browser
import Model exposing (Msg(..), init, subscriptions, update)
import View.View exposing (view)


{-| Browser.application would work fine for the web version of mapwatch, but
sadly, it fails for the electron version because its urls use a protocol
other than http/https. So instead, we use Browser.document and deal with
urls via ports.
-}
main =
    Browser.document
        -- Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view

        -- clicking a link
        -- , onUrlRequest = NavRequest
        -- altering the address bar, or other url changes
        -- , onUrlChange = NavLocation
        }
