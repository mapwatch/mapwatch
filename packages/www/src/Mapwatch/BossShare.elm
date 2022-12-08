module Mapwatch.BossShare exposing
    ( BossShare
    , base64Decode
    , base64Encode
    , create
    , jsonDecode
    , jsonEncode
    )

import Base64
import Json.Decode as D
import Json.Encode as E
import Mapwatch.BossTally as BossTally exposing (BossTally)


type alias BossShare =
    { version : Int
    , tally : BossTally
    }


create : BossTally -> BossShare
create =
    BossShare 1


jsonEncode : BossShare -> D.Value
jsonEncode s =
    E.object
        [ ( "version", s.version |> E.int )
        , ( "tally", s.tally |> BossTally.jsonEncode )
        ]


jsonDecode : D.Decoder BossShare
jsonDecode =
    D.map2 BossShare
        (D.field "version" D.int)
        (D.field "tally" BossTally.jsonDecode)


base64Encode : BossShare -> String
base64Encode =
    jsonEncode >> E.encode 0 >> Base64.encode


base64Decode : String -> Result String BossShare
base64Decode =
    Base64.decode >> Result.andThen (D.decodeString jsonDecode >> Result.mapError D.errorToString)
