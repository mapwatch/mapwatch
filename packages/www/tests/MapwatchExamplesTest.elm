module MapwatchExamplesTest exposing (..)

import Expect
import Fixture exposing (datamine)
import Fixture.Examples
import Mapwatch
import Mapwatch.BossTally as BossTally
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
                            >> BossTally.aggregate
                            >> Expect.all
                                [ .atziri >> .uber >> BossTally.isUnvisited >> Expect.true "uber atziri unvisited"
                                , .eater >> .uber >> BossTally.isUnvisited >> Expect.true "uber eater unvisited"
                                , .eater >> .standard >> BossTally.isVictoryExact >> Expect.true "eater victory"
                                , .exarch >> .uber >> BossTally.isUnvisited >> Expect.true "uber exarch unvisited"
                                , .exarch >> .standard >> BossTally.isVictoryExact >> Expect.true "exarch victory"
                                , .hunger >> BossTally.isVictoryExact >> Expect.true "hunger victory"
                                , .blackstar >> BossTally.isVictoryExact >> Expect.true "blackstar victory"
                                , .drox >> BossTally.isUnvisited >> Expect.true "drox unvisited"
                                , .shaperHydra >> BossTally.isUnvisited >> Expect.true "hydra unvisited"
                                ]
                        ]
        , test "bosses" <|
            \_ ->
                Fixture.Examples.bosses
                    |> mapRuns
                    |> List.filterMap .bossTally
                    |> BossTally.aggregate
                    |> Expect.all
                        [ .atziri >> .uber >> BossTally.isVisitedExact >> Expect.true "uber atziri visited"
                        , .eater >> .uber >> BossTally.isUnvisited >> Expect.true "uber eater unvisited"
                        , .eater >> .standard >> BossTally.isVictoryExact >> Expect.true "eater victory"
                        , .exarch >> .uber >> BossTally.isUnvisited >> Expect.true "uber exarch unvisited"
                        , .exarch >> .standard >> BossTally.isVictoryExact >> Expect.true "exarch victory"
                        , .hunger >> BossTally.isVictoryExact >> Expect.true "hunger victory"
                        , .blackstar >> BossTally.isVictoryExact >> Expect.true "blackstar victory"

                        -- baran's important to test, because we're matching multiline completion dialogue (his long "Kirac... sent you?" line)
                        , .baran >> BossTally.isLogoutless >> Expect.true "baran logoutless"
                        , .drox >> BossTally.isDeathlessExact >> Expect.true "drox deathless"
                        , .shaperHydra >> BossTally.isLogoutless >> Expect.true "hydra logoutless"
                        ]
        ]
