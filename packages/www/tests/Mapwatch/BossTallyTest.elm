module Mapwatch.BossTallyTest exposing (..)

import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as D
import Mapwatch.BossEntry as BossEntry exposing (BossEntry)
import Mapwatch.BossTally as BossTally exposing (BossTally, UberBossEntry)
import Random
import Test exposing (..)
import Time exposing (Posix)


tally : Fuzzer BossTally
tally =
    Fuzz.constant BossTally
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap uberEntry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry
        |> Fuzz.andMap entry


uberEntry : Fuzzer UberBossEntry
uberEntry =
    Fuzz.map2 UberBossEntry entry entry


entry : Fuzzer BossEntry
entry =
    Fuzz.oneOf
        [ BossEntry.Unvisited |> Fuzz.constant
        , visitedData |> Fuzz.map BossEntry.Visited
        , victoryData |> Fuzz.map BossEntry.Victory
        , deathlessData |> Fuzz.map BossEntry.Deathless
        , logoutlessData |> Fuzz.map BossEntry.Logoutless
        ]


visitedData : Fuzzer BossEntry.VisitedData
visitedData =
    Fuzz.map2 BossEntry.VisitedData timestamp positiveInt


victoryData : Fuzzer BossEntry.VictoryData
victoryData =
    Fuzz.map3 BossEntry.VictoryData timestamp positiveInt visitedData


deathlessData : Fuzzer BossEntry.DeathlessData
deathlessData =
    Fuzz.map3 BossEntry.DeathlessData timestamp positiveInt victoryData


logoutlessData : Fuzzer BossEntry.LogoutlessData
logoutlessData =
    Fuzz.map3 BossEntry.LogoutlessData timestamp positiveInt deathlessData


timestamp : Fuzzer Posix
timestamp =
    positiveInt |> Fuzz.map Time.millisToPosix


positiveInt : Fuzzer Int
positiveInt =
    Fuzz.intRange 0 Random.maxInt


all : Test
all =
    describe "BossTally"
        [ fuzz tally "json encode/decode match" <|
            \t ->
                t
                    |> BossTally.jsonEncode
                    |> D.decodeValue BossTally.jsonDecode
                    |> Expect.equal (Ok t)
        ]
