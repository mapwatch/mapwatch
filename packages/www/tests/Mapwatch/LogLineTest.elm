module Mapwatch.LogLineTest exposing (..)

import Expect
import Fixture exposing (datamine)
import Mapwatch
import Mapwatch.LogLine as LogLine
import Settings
import Test exposing (..)
import Time exposing (Posix)


expectParseEquals : String -> Result String ( Int, LogLine.Info ) -> Expect.Expectation
expectParseEquals raw result0 =
    let
        result : Result LogLine.ParseError LogLine.Line
        result =
            result0
                |> Result.map (\( t, i ) -> { raw = raw, position = 69, date = Time.millisToPosix t, info = i })
                |> Result.mapError (\e -> { raw = raw, position = 69, err = e })
    in
    LogLine.parse datamine Time.utc ( 69, raw )
        |> Expect.equal result


all : Test
all =
    describe "LogLine"
        -- many of these tests come from the example link on the front page
        [ test "opening" <|
            \_ ->
                expectParseEquals
                    "2018/05/13 16:05:37 ***** LOG FILE OPENING *****"
                    (Ok ( 1526227537000, LogLine.Opening ))
        , test "connecting" <|
            \_ ->
                expectParseEquals
                    "2018/05/13 16:10:08 1795218 d8 [INFO Client 1636] Connecting to instance server at 169.63.67.235:6112"
                    (Ok ( 1526227808000, LogLine.ConnectingToInstanceServer "169.63.67.235:6112" ))
        , test "entering" <|
            \_ ->
                expectParseEquals
                    "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] : You have entered The Twilight Strand."
                    (Ok ( 1526227814000, LogLine.YouHaveEntered "The Twilight Strand" ))
        , test "special russian log prefix: https://github.com/mapwatch/mapwatch/issues/273" <|
            \_ ->
                expectParseEquals
                    "2021/06/19 10:23:03 804993734 bad [INFO Client 42068] : <<set:MS>><<set:M>><<set:S>>Вы вошли в область Берега Каруи."
                    (Ok ( 1624098183000, LogLine.YouHaveEntered "Берега Каруи" ))
        , test "afk enabled" <|
            \_ ->
                expectParseEquals
                    "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] : AFK mode is now ON. Autoreply \"toucan lol\""
                    (Ok ( 1526227814000, LogLine.AFKMode True ))
        , test "afk disabled" <|
            \_ ->
                expectParseEquals
                    "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] : AFK mode is now OFF."
                    (Ok ( 1526227814000, LogLine.AFKMode False ))
        , describe "chat ignored"
            [ test "opening" <|
                \_ ->
                    expectParseEquals
                        "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: ***** LOG FILE OPENING *****"
                        (Err "logline not recognized")
            , test "connecting" <|
                \_ ->
                    expectParseEquals
                        "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: 1801062 9b0 [INFO Client 1636] Connecting to instance server at 169.63.67.235:6112"
                        (Err "logline not recognized")
            , test "entering" <|
                \_ ->
                    expectParseEquals
                        "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: You have entered The Twilight Strand."
                        (Err "logline not recognized")
            , test "entering 2" <|
                \_ ->
                    expectParseEquals
                        "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: 1801062 9b0 [INFO Client 1636] : You have entered The Twilight Strand."
                        (Err "logline not recognized")
            ]
        , describe "log filtering"
            [ test "filtered logs" <|
                \_ ->
                    [ "2018/05/13 16:10:08 1795218 d8 [INFO Client 1636] Connecting to instance server at 169.63.67.235:6112"
                    , "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: 1801062 9b0 [INFO Client 1636] Connecting to instance server at 1.2.3.4:6112"
                    , "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] : You have entered The Twilight Strand."
                    , "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] SomeJerkInLocalChat: 1801062 9b0 [INFO Client 1636] : You have entered The Twilight Zone."
                    , "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] Einhar, Beastmaster: I'm an NPC with dialogue!"
                    , "2018/05/13 16:10:14 1801062 9b0 [INFO Client 1636] Alva, Master Explorer: I'm an NPC with multiline dialogue, "
                    , "and at least my first line must survive!"
                    , ""
                    , "and let's throw in some dialogue with a ] just for fun"
                    , "2018/05/13 16:10:15 1795218 d8 [INFO Client 1636] Connecting to instance server at 169.63.67.236:6112"
                    , "2018/05/13 16:10:16 1795218 d8 [INFO Client 1636] Connecting to instance server at 169.63.67.235:6112"
                    ]
                        |> String.join "\n"
                        |> Mapwatch.filteredLogSlice Time.utc datamine Settings.empty 0
                        |> Expect.all
                            [ Expect.equal
                                ([ "2018/05/13 16:10:08 ] Connecting to instance server at 999.999.999.0:6112"
                                 , "2018/05/13 16:10:14 ] : You have entered The Twilight Strand."
                                 , "2018/05/13 16:10:14 ] Einhar, Beastmaster: I'm an NPC with dialogue!"
                                 , "2018/05/13 16:10:14 ] Alva, Master Explorer: I'm an NPC with multiline dialogue, "

                                 -- https://github.com/mapwatch/mapwatch/issues/61
                                 -- , "and at least my first line must survive!"
                                 -- , ""
                                 -- , "and let's throw in some dialogue with a ] just for fun"
                                 --
                                 -- preserve ip uniqueness: if an ip is repeated in the original, repeat it here too
                                 , "2018/05/13 16:10:15 ] Connecting to instance server at 999.999.999.1:6112"
                                 , "2018/05/13 16:10:16 ] Connecting to instance server at 999.999.999.0:6112"
                                 ]
                                    |> String.join "\n"
                                )
                            , \filtered ->
                                filtered
                                    -- we can parse filtered output, and it produces identical results
                                    |> Mapwatch.filteredLogSlice Time.utc datamine Settings.empty 0
                                    |> Mapwatch.filteredLogSlice Time.utc datamine Settings.empty 0
                                    |> Mapwatch.filteredLogSlice Time.utc datamine Settings.empty 0
                                    |> Mapwatch.filteredLogSlice Time.utc datamine Settings.empty 0
                                    |> Expect.equal filtered
                            ]
            ]
        ]
