module Mapwatch.BossShareTest exposing (..)

import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as D
import Mapwatch.BossEntry as BossEntry exposing (BossEntry)
import Mapwatch.BossShare as BossShare exposing (BossShare)
import Mapwatch.BossTally as BossTally exposing (BossTally, UberBossEntry)
import Random
import Test exposing (..)
import Time exposing (Posix)


share : Fuzzer BossShare
share =
    Fuzz.map BossShare.create
        tally


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
    Fuzz.map BossEntry.VisitedData timestamp


victoryData : Fuzzer BossEntry.VictoryData
victoryData =
    Fuzz.map3 BossEntry.VictoryData timestamp positiveInt visitedData


deathlessData : Fuzzer BossEntry.DeathlessData
deathlessData =
    Fuzz.map2 BossEntry.DeathlessData timestamp victoryData


logoutlessData : Fuzzer BossEntry.LogoutlessData
logoutlessData =
    Fuzz.map2 BossEntry.LogoutlessData timestamp deathlessData


timestamp : Fuzzer Posix
timestamp =
    positiveInt |> Fuzz.map Time.millisToPosix


positiveInt : Fuzzer Int
positiveInt =
    Fuzz.intRange 0 Random.maxInt


all : Test
all =
    describe "BossShare"
        [ fuzz share "json encode/decode match" <|
            \t ->
                t
                    |> BossShare.jsonEncode
                    |> D.decodeValue BossShare.jsonDecode
                    |> Expect.equal (Ok t)
        , fuzz share "base64 encode/decode match" <|
            \t ->
                t
                    |> BossShare.base64Encode
                    |> BossShare.base64Decode
                    |> Expect.equal (Ok t)
        ]
