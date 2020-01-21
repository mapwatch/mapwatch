module RouteTest exposing (..)

import Dict exposing (Dict)
import Expect
import Route exposing (Route)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Test exposing (..)
import Url exposing (Url)


url : String -> Url
url s =
    case Url.fromString s of
        Nothing ->
            Debug.todo <| "invalid url: " ++ s

        Just u ->
            u


all : Test
all =
    describe "Route"
        [ test "parse" <|
            \_ ->
                Route.parse (url "https://example.com#")
                    |> Expect.equal ( Route.Timer, Dict.empty )
        , test "tostring" <|
            \_ ->
                Route.parse (url "https://example.com#")
                    |> (\( r, q ) -> Route.toString q r)
                    |> Expect.equal "#"
        , test "tostring: bogus query" <|
            \_ ->
                Route.parse (url "https://example.com#?foo=bar")
                    |> Expect.equal ( Route.Timer, Dict.empty )
        , test "tostring: ok query" <|
            \_ ->
                Route.parse (url "https://example.com#?foo=bar&a=a")
                    |> Expect.equal ( Route.Timer, Dict.fromList [ ( "a", "a" ) ] )
        ]
