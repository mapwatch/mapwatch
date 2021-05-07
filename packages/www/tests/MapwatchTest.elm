module MapwatchTest exposing (..)

import Dict exposing (Dict)
import Expect
import Fixture exposing (datamine)
import Mapwatch exposing (Model)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.MapRun as MapRun exposing (Durations, MapRun)
import Set exposing (Set)
import Settings exposing (Settings)
import Test exposing (..)
import Time exposing (Posix)


emptyRun : MapRun
emptyRun =
    { address = { addr = "", worldArea = Nothing, zone = "" }
    , duration = emptyDuration
    , heistNpcs = Set.empty
    , conqueror = Nothing
    , isAbandoned = False
    , isBlightedMap = False
    , isGrandHeist = Nothing
    , isHeartOfTheGrove = False
    , npcSays = Dict.empty
    , portals = 0
    , positionEnd = 0
    , positionStart = 0
    , rootNpcs = Set.empty
    , sideAreas = Dict.empty
    , startedAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    , trialmaster = []
    }


emptyDuration : Durations
emptyDuration =
    { afk = 0
    , all = 0
    , mainMap = 0
    , notTown = 0
    , sides = 0
    , town = 0
    }


address : String -> String -> String -> Address
address addr id zone =
    { addr = addr, zone = zone, worldArea = Just <| Fixture.worldArea id datamine }


crlfFix =
    -- don't let git core.autocrlf derail test results
    String.replace "\u{000D}" ""


all : Test
all =
    describe "Mapwatch" <|
        [ test "parse empty" <|
            \_ ->
                """
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    |> Expect.equal []
        , test "parse simple" <|
            \_ ->
                """
2021/05/06 03:17:36 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:17:38 ] : You have entered Residence.
2021/05/06 03:23:39 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:23:39 ] : You have entered Stately Hideout.
2021/05/06 03:24:08 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:24:09 ] : You have entered Residence.
2021/05/06 03:27:30 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:27:31 ] : You have entered Stately Hideout.
2021/05/06 03:32:49 ] Connecting to instance server at 999.999.999.2:6112
2021/05/06 03:32:51 ] : You have entered Port.
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    -- |> Expect.equal []
                    |> Expect.equal
                        [ { emptyRun
                            | address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                            , duration =
                                { emptyDuration
                                    | all = 913000
                                    , mainMap = 563000
                                    , notTown = 563000
                                    , town = 350000
                                }
                            , portals = 2
                            , positionEnd = 637
                            , positionStart = 1
                            , startedAt = Time.millisToPosix 1620271058000
                            , updatedAt = Time.millisToPosix 1620271971000
                          }
                        ]
        ]
