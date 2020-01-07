module View.DebugDatamine exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch.Datamine exposing (Datamine)


view : Result String Datamine -> Html msg
view rdatamine =
    case rdatamine of
        Err err ->
            pre [] [ text err ]

        Ok datamine ->
            pre [] [ text <| Debug.toString datamine ]
