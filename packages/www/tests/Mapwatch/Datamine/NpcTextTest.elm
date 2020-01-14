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
        ]
