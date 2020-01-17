module Settings exposing (Settings, decoder, empty, encoder)

{-| Persistent settings. Remembered across visits via localstorage.
-}

import Json.Decode as D
import Json.Encode as E


type alias Settings =
    { volume : Int }


empty : Settings
empty =
    { volume = 0
    }


decoder : D.Decoder Settings
decoder =
    D.map Settings
        (D.field "volume" (D.int |> D.map (clamp 0 100)))


encoder : Settings -> E.Value
encoder s =
    E.object
        [ ( "volume", s.volume |> E.int )
        ]
