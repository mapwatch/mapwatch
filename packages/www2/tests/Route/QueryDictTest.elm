module Route.QueryDictTest exposing (..)

import Dict exposing (Dict)
import Expect
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import Test exposing (..)
import Url exposing (Url)


all : Test
all =
    describe "Route.QueryDict"
        [ test "nothing" <|
            \_ ->
                QueryDict.fromString ""
                    |> Expect.equal Dict.empty
        , test "one" <|
            \_ ->
                QueryDict.fromString "foo=bar"
                    |> Expect.equal (Dict.fromList [ ( "foo", "bar" ) ])
        , test "two" <|
            \_ ->
                QueryDict.fromString "foo=bar&baz=quux"
                    |> Expect.equal (Dict.fromList [ ( "foo", "bar" ), ( "baz", "quux" ) ])
        , test "dupe" <|
            \_ ->
                QueryDict.fromString "foo=bar&foo=quux"
                    |> Expect.equal (Dict.fromList [ ( "foo", "quux" ) ])
        , test "url:query" <|
            \_ ->
                Url.fromString "https://example.com?foo=bar#/?baz=quux"
                    |> Maybe.map QueryDict.fromUrlQuery
                    |> Expect.equal (Just <| Dict.fromList [ ( "foo", "bar" ) ])
        , test "url:hash" <|
            \_ ->
                Url.fromString "https://example.com?foo=bar#/?baz=quux"
                    |> Maybe.map QueryDict.fromUrlFragment
                    |> Expect.equal (Just <| Dict.fromList [ ( "foo", "bar" ), ( "baz", "quux" ) ])
        , test "tostring" <|
            \_ ->
                QueryDict.fromString "foo=bar&baz=quux"
                    |> QueryDict.toString { prefix = True, filter = Nothing }
                    |> Expect.equal "?baz=quux&foo=bar"
        , test "tostring noprefix" <|
            \_ ->
                QueryDict.fromString "foo=bar&baz=quux"
                    |> QueryDict.toString { prefix = False, filter = Nothing }
                    |> Expect.equal "baz=quux&foo=bar"
        , test "tostring filter" <|
            \_ ->
                QueryDict.fromString "foo=bar&baz=quux"
                    |> QueryDict.toString { prefix = True, filter = Just <| Set.singleton "foo" }
                    |> Expect.equal "?foo=bar"
        , test "parse escape chars" <|
            \_ ->
                QueryDict.fromString "a%20b%20c=d%20e%20f"
                    |> Expect.equal (Dict.fromList [ ( "a b c", "d e f" ) ])
        , test "stringify escape chars" <|
            \_ ->
                QueryDict.fromString "a%20b%20c=d%20e%20f"
                    |> QueryDict.toString { prefix = False, filter = Nothing }
                    |> Expect.equal "a%20b%20c=d%20e%20f"
        ]
