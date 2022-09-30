module MapwatchExamplesTest exposing (..)

import Expect
import Fixture exposing (datamine)
import Fixture.Examples
import Json.Decode as D
import Mapwatch
import Mapwatch.BossEntry as BossEntry
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
                                [ .atziri >> .uber >> BossEntry.isUnvisited >> Expect.true "uber atziri unvisited"
                                , .eater >> .uber >> BossEntry.isUnvisited >> Expect.true "uber eater unvisited"
                                , .eater >> .standard >> BossEntry.isVictoryExact >> Expect.true "eater victory"
                                , .exarch >> .uber >> BossEntry.isUnvisited >> Expect.true "uber exarch unvisited"
                                , .exarch >> .standard >> BossEntry.isVictoryExact >> Expect.true "exarch victory"
                                , .hunger >> BossEntry.isVictoryExact >> Expect.true "hunger victory"
                                , .blackstar >> BossEntry.isVictoryExact >> Expect.true "blackstar victory"
                                , .drox >> BossEntry.isUnvisited >> Expect.true "drox unvisited"
                                , .shaperHydra >> BossEntry.isUnvisited >> Expect.true "hydra unvisited"
                                , \tally -> tally |> BossTally.jsonEncode |> D.decodeValue BossTally.jsonDecode |> Expect.equal (Ok tally)
                                ]
                        ]
        , test "bosses" <|
            \_ ->
                Fixture.Examples.bosses
                    |> mapRuns
                    |> List.filterMap .bossTally
                    |> BossTally.aggregate
                    |> Expect.all
                        [ .atziri >> .uber >> BossEntry.isVisitedExact >> Expect.true "uber atziri visited"
                        , .eater >> .uber >> BossEntry.isUnvisited >> Expect.true "uber eater unvisited"
                        , .eater >> .standard >> BossEntry.isVictoryExact >> Expect.true "eater victory"
                        , .exarch >> .uber >> BossEntry.isUnvisited >> Expect.true "uber exarch unvisited"
                        , .exarch >> .standard >> BossEntry.isVictoryExact >> Expect.true "exarch victory"
                        , .hunger >> BossEntry.isVictoryExact >> Expect.true "hunger victory"
                        , .blackstar >> BossEntry.isVictoryExact >> Expect.true "blackstar victory"

                        -- baran's important to test, because we're matching multiline completion dialogue (his long "Kirac... sent you?" line)
                        , .baran >> BossEntry.isLogoutless >> Expect.true "baran logoutless"
                        , .drox >> BossEntry.isDeathlessExact >> Expect.true "drox deathless"
                        , .shaperHydra >> BossEntry.isLogoutless >> Expect.true "hydra logoutless"
                        , \tally -> tally |> BossTally.jsonEncode |> D.decodeValue BossTally.jsonDecode |> Expect.equal (Ok tally)
                        ]
        ]
