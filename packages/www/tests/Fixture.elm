module Fixture exposing (datamine, worldArea)

import Dict exposing (Dict)
import Fixture.Json
import Json.Decode as D
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea, langIndexEmpty)


datamine : Datamine
datamine =
    case D.decodeString Datamine.decoder Fixture.Json.datamine of
        Err err ->
            Debug.todo <| "datamine decode failure: " ++ D.errorToString err

        Ok dm ->
            dm


worldArea : String -> Datamine -> WorldArea
worldArea id dm =
    case Dict.get id dm.worldAreasById of
        Nothing ->
            Debug.todo <| "no such worldArea: " ++ id

        Just w ->
            w
