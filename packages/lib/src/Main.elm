module Main exposing (main)

import Platform
import Mapwatch exposing (initModel, update, subscriptions)
import Mapwatch.Route as Route


main =
    Platform.programWithFlags
        -- Route is irrelevant since this isn't web
        { init = \flags -> ( initModel flags Route.Debug, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        }
