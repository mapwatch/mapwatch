module Fixture exposing (datamine)

import Fixture.Json
import Json.Decode as D
import Mapwatch.Datamine as Datamine exposing (Datamine, langIndexEmpty)


datamine : Datamine
datamine =
    case D.decodeString Datamine.decoder Fixture.Json.datamine of
        Err err ->
            Debug.todo <| "datamine decode failure: " ++ D.errorToString err

        Ok dm ->
            dm
