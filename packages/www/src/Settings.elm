module Settings exposing (Settings, decoder, empty, encoder)

{-| Persistent settings. Remembered across visits via localstorage.
-}

import Json.Decode as D
import Json.Encode as E
import Maybe.Extra


type alias Settings =
    { volume : Int
    , spreadsheetId : Maybe String
    }


empty : Settings
empty =
    { volume = 0
    , spreadsheetId = Nothing
    }


decoder : D.Decoder Settings
decoder =
    D.map2 Settings
        (D.field "volume" (D.int |> D.map (clamp 0 100)))
        (D.maybe <| D.field "spreadsheetId" D.string)


encoder : Settings -> E.Value
encoder s =
    E.object
        [ ( "volume", s.volume |> E.int )
        , ( "spreadsheetId", s.spreadsheetId |> Maybe.Extra.unwrap E.null E.string )
        ]
