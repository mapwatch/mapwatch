module MapwatchExamplesTest exposing (..)

import MapwatchTest exposing (emptyRun, emptyDuration, address, crlfFix)
import Expect
import Mapwatch
import Mapwatch.MapRun exposing (MapRun)
import Fixture exposing (datamine)
import Fixture.Examples
import Settings exposing (Settings)
import Time
import Test exposing (..)

mapRuns : String -> List MapRun
mapRuns =
    crlfFix >> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0 >> .runs

all : Test
all =
    describe "Mapwatch Examples" <|
        [ test "frontpage" <|
            \_ ->
                Fixture.Examples.stripped_client
                    |> mapRuns
                    |> List.length
                    |> Expect.equal 63
        , test "laboratory map vs heist" <|
            \_ ->
                case Fixture.Examples.laboratory |> mapRuns of
                    a :: b :: [] ->
                        () |> Expect.all
                            [ \_ -> a.address.zone |> Expect.equal "Laboratory"
                            , \_ -> b.address.zone |> Expect.equal "Laboratory"
                            , \_ -> a.address.worldArea |> Maybe.map .id |> Expect.equal (Just "MapWorldsLaboratory")
                            , \_ -> b.address.worldArea |> Maybe.map .id |> Expect.equal (Just "HeistDungeon1")
                            ]
                    _ -> Expect.true "wrong number of runs" False
        , test "chinese client" <|
            \_ ->
                Fixture.Examples.chinese_client
                    |> mapRuns
                    |> List.length
                    |> Expect.equal 1
        ]
