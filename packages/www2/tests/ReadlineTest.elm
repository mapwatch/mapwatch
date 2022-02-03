module ReadlineTest exposing (..)

import Expect
import Readline exposing (Progress, Readline)
import Test exposing (..)


all : Test
all =
    describe "Readline" <|
        [ test "parse unbuffered" <|
            \_ ->
                Readline.create { start = 10, end = 100 }
                    |> Readline.read -1 "hello\nworld\nfoo"
                    |> Expect.equal ( [ ( 10, "hello" ), ( 16, "world" ) ], { start = 10, end = 100, cursor = 25, lineBuffer = "foo" } )
        , test "parse buffered" <|
            \_ ->
                { start = 10, end = 100, cursor = 25, lineBuffer = "foo" }
                    |> Readline.read -1 "bar\nbaz\nquux\n"
                    |> Expect.equal ( [ ( 22, "foobar" ), ( 29, "baz" ), ( 33, "quux" ) ], { start = 10, end = 100, cursor = 38, lineBuffer = "" } )
        , test "parse unbuffered windows" <|
            \_ ->
                Readline.create { start = 10, end = 100 }
                    -- elm-format is reformatting \r
                    |> Readline.read -1 "hello\u{000D}\nworld\u{000D}\nfoo"
                    |> Expect.equal ( [ ( 10, "hello" ), ( 17, "world" ) ], { start = 10, end = 100, cursor = 27, lineBuffer = "foo" } )
        , test "parse buffered windows" <|
            \_ ->
                { start = 10, end = 100, cursor = 27, lineBuffer = "foo" }
                    -- elm-format is reformatting \r
                    |> Readline.read -1 "bar\u{000D}\nbaz\u{000D}\nquux\u{000D}\n"
                    |> Expect.equal ( [ ( 24, "foobar" ), ( 32, "baz" ), ( 37, "quux" ) ], { start = 10, end = 100, cursor = 43, lineBuffer = "" } )
        , test "parse non-ascii" <|
            \_ ->
                Readline.create { start = 10, end = 100 }
                    |> Readline.read -1 "今日は\nworld\nfoo"
                    |> Expect.equal ( [ ( 10, "今日は" ), ( 20, "world" ) ], { start = 10, end = 100, cursor = 29, lineBuffer = "foo" } )
        ]
