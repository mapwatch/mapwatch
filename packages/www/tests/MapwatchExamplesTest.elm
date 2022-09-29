module MapwatchExamplesTest exposing (..)

import Expect
import Fixture exposing (datamine)
import Fixture.Examples
import Mapwatch
import Mapwatch.BossTally
import Mapwatch.MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as Sort
import MapwatchTest exposing (address, crlfFix, emptyDuration, emptyRun)
import Settings exposing (Settings)
import Test exposing (..)
import Time


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
                        ()
                            |> Expect.all
                                [ \_ -> a.address.zone |> Expect.equal "Laboratory"
                                , \_ -> b.address.zone |> Expect.equal "Laboratory"
                                , \_ -> a.address.worldArea |> Maybe.map .id |> Expect.equal (Just "MapWorldsLaboratory")
                                , \_ -> b.address.worldArea |> Maybe.map .id |> Expect.equal (Just "HeistDungeon1")
                                ]

                    _ ->
                        Expect.true "wrong number of runs" False
        , test "chinese client" <|
            \_ ->
                Fixture.Examples.chinese_client
                    |> mapRuns
                    |> List.length
                    |> Expect.equal 1
        , test "siege: eater and exarch" <|
            \_ ->
                Fixture.Examples.siege_eater_exarch
                    |> mapRuns
                    |> Expect.all
                        [ List.length >> Expect.equal 4
                        , Sort.search datamine "exarch" >> List.length >> Expect.equal 1
                        , Sort.search datamine "black star" >> List.length >> Expect.equal 1
                        , Sort.search datamine "eater" >> List.length >> Expect.equal 1
                        , Sort.search datamine "hunger" >> List.length >> Expect.equal 1
                        , Sort.search datamine "bogus" >> List.length >> Expect.equal 0
                        , List.filterMap .bossTally
                            >> Mapwatch.BossTally.aggregate
                            >> Expect.all
                                [ .atziri >> .uber >> Expect.equal { runs = 0, minDeaths = Nothing, totalDeaths = 0 }
                                , .eater >> .uber >> Expect.equal { runs = 0, completed = 0, minDeaths = Nothing, totalDeaths = 0 }
                                , .eater >> .standard >> Expect.equal { runs = 1, completed = 1, minDeaths = Just 4, totalDeaths = 4 }
                                , .exarch >> .uber >> Expect.equal { runs = 0, completed = 0, minDeaths = Nothing, totalDeaths = 0 }
                                , .exarch >> .standard >> Expect.equal { runs = 1, completed = 1, minDeaths = Just 2, totalDeaths = 2 }
                                , .hunger >> Expect.equal { runs = 1, completed = 1, minDeaths = Just 1, totalDeaths = 1 }
                                , .blackstar >> Expect.equal { runs = 1, completed = 1, minDeaths = Just 4, totalDeaths = 4 }
                                ]
                        ]
        ]
