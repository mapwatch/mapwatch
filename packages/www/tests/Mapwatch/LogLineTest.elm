module Mapwatch.LogLineTest exposing (..)

import Array
import Dict
import Expect
import Mapwatch.Datamine as Datamine exposing (Datamine, langIndexEmpty)
import Mapwatch.LogLine as LogLine
import Test exposing (..)
import Time exposing (Posix)


datamine : Datamine
datamine =
    Datamine.createDatamine_ Array.empty
        (Dict.singleton Datamine.defaultLang
            { name = Datamine.defaultLang
            , unindex = langIndexEmpty
            , index = { langIndexEmpty | backendErrors = Dict.singleton "EnteredArea" "You have entered {0}." }
            }
        )
        []
        Dict.empty
        []
        []
        Dict.empty


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
        ]
