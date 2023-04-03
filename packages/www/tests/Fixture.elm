module Fixture exposing (datamine, dictGetOrDie, ultimatumMod, worldArea)

import Dict exposing (Dict)
import Fixture.Examples
import Fixture.Json
import Json.Decode as D
import Mapwatch.Datamine as Datamine exposing (Datamine, UltimatumModifier, WorldArea, langIndexEmpty)
import Mapwatch.Datamine.Trialmaster as DMTrialmaster


datamine : Datamine
datamine =
    case D.decodeString Datamine.decoder Fixture.Json.datamine of
        Err err ->
            Debug.todo <| "datamine decode failure: " ++ D.errorToString err

        Ok dm ->
            dm


worldArea : String -> Datamine -> WorldArea
worldArea id dm =
    dictGetOrDie "no such worldArea" id dm.worldAreasById


ultimatumMod : String -> Datamine -> UltimatumModifier
ultimatumMod id dm =
    dictGetOrDie "no such ultimatumMod" id dm.ultimatumModifiersById


dictGetOrDie : String -> comparable -> Dict comparable v -> v
dictGetOrDie err k dict =
    case Dict.get k dict of
        Just v ->
            v

        Nothing ->
            Debug.todo <| err ++ ": " ++ Debug.toString k
