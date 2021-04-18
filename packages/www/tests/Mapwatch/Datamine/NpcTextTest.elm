module Mapwatch.Datamine.NpcTextTest exposing (..)

import Expect
import Mapwatch.Datamine.NpcText as NpcText
import Test exposing (..)


all : Test
all =
    describe "Mapwatch.Datamine.NpcText"
        [ test "plaintext" <|
            \_ ->
                NpcText.parse "blah"
                    |> Expect.equal (Ok [ "blah" ])
        , test "italics" <|
            \_ ->
                NpcText.parse "tell zana... <italic>{demons...}"
                    |> Expect.equal (Ok [ "tell zana... demons..." ])
        , test "gendered" <|
            \_ ->
                NpcText.parse "bonjour <if:MS>{exilé}<elif:FS>{exilée}"
                    |> Expect.equal (Ok [ "bonjour exilé", "bonjour exilée" ])
        , test "unexpected" <|
            \_ ->
                NpcText.parse "<if:NS>{blah}"
                    |> Expect.err
        , test "hidden thai characters 0" <|
            \_ ->
                -- 3.13ish thai BaranFourStoneDeatha
                NpcText.parse "บอก\u{200B}ซานะ\u{200B}... ... ... <italic\u{200B}>{\u{200B}มาร\u{200B}ร้าย\u{200B}}..."
                    |> Expect.ok
        , test "hidden thai characters 1" <|
            \_ ->
                -- 3.14.0 thai VinderiDemolitionFour
                NpcText.parse "งาน\u{200B}นี้\u{200B}ต้องการ\u{200B}ระเบิด\u{200B}ลูก<b>{\u{200B}เบ้อเร่อ}\u{200B}นะ"
                    |> Expect.ok
        ]
