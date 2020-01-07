module DemoMain exposing (main)

import Mapwatch exposing (Model, Msg, init, subscriptions, update)
import Platform


main : Program () Model Msg
main =
    Platform.worker
        { init = always init
        , update = update
        , subscriptions = subscriptions
        }
