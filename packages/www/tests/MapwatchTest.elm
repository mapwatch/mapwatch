module MapwatchTest exposing (..)

import Dict exposing (Dict)
import Expect
import Fixture exposing (datamine)
import Mapwatch exposing (Model)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.MapRun as MapRun exposing (Durations, MapRun)
import Mapwatch.MapRun.Trialmaster as Trialmaster
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
        , test "parse trialmaster" <|
            \_ ->
                """
2021/05/06 03:17:36 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:17:38 ] : You have entered Residence.
2021/05/06 03:17:38 ] The Trialmaster: One loss is nothing to be ashamed of.
2021/05/06 03:17:38 ] The Trialmaster: Vengeance is cold indeed.
2021/05/06 03:17:39 ] The Trialmaster: This is no longer amusing.
2021/05/06 03:27:30 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:27:31 ] : You have entered Stately Hideout.
2021/05/06 03:32:49 ] Connecting to instance server at 999.999.999.2:6112
2021/05/06 03:32:51 ] : You have entered Port.
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    |> List.map
                        (\r ->
                            { r
                              -- more work than it's worth to verify these
                                | npcSays = Dict.empty
                                , rootNpcs = Set.empty
                                , trialmaster =
                                    r.trialmaster
                                        |> List.map (\t -> { t | says = [] })
                            }
                        )
                    |> Expect.equal
                        [ { emptyRun
                            | address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                            , duration =
                                { emptyDuration
                                    | all = 913000
                                    , mainMap = 593000
                                    , notTown = 593000
                                    , town = 320000
                                    , sides = 1000
                                }
                            , portals = 1
                            , positionEnd = 587
                            , positionStart = 1
                            , startedAt = Time.millisToPosix 1620271058000
                            , updatedAt = Time.millisToPosix 1620271971000
                            , trialmaster =
                                [ { address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                                  , outcome = Trialmaster.Won 1000
                                  , isBossFight = False
                                  , mods =
                                        List.map Ok
                                            [ Fixture.ultimatumMod "FrostInfectionDaemon1" datamine
                                            ]
                                  , says = []
                                  }
                                ]
                          }
                        ]
        , test "parse trialmaster boss win" <|
            \_ ->
                """
2021/05/06 03:17:36 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:17:38 ] : You have entered Residence.
2021/05/06 03:17:39 ] The Trialmaster: Your luck will run out soon, challenger.
2021/05/06 03:17:39 ] The Trialmaster: You will fall to ruin.
2021/05/06 03:17:39 ] The Trialmaster: Ruin arrives suddenly.
2021/05/06 03:17:39 ] The Trialmaster: Shrapnel and shards abound.
2021/05/06 03:17:39 ] The Trialmaster: You shall suffer your own bile.
2021/05/06 03:17:39 ] The Trialmaster: Relentless assault.
2021/05/06 03:17:39 ] The Trialmaster: Be torn to shreds.
2021/05/06 03:17:39 ] The Trialmaster: Time is your enemy.
2021/05/06 03:17:39 ] The Trialmaster: Night's madness drains away all hope.
2021/05/06 03:17:39 ] The Trialmaster: Can you feel death coiling around your heart?
2021/05/06 03:17:39 ] The Trialmaster: Vengeance is cold indeed.
2021/05/06 03:17:39 ] The Trialmaster: Time to end this!
2021/05/06 03:17:40 ] The Trialmaster: My service... is finally over...
2021/05/06 03:27:30 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:27:31 ] : You have entered Stately Hideout.
2021/05/06 03:32:49 ] Connecting to instance server at 999.999.999.2:6112
2021/05/06 03:32:51 ] : You have entered Port.
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    |> List.map
                        (\r ->
                            { r
                              -- more work than it's worth to verify these
                                | npcSays = Dict.empty
                                , rootNpcs = Set.empty
                                , trialmaster =
                                    r.trialmaster
                                        |> List.map (\t -> { t | says = [] })
                            }
                        )
                    |> Expect.equal
                        [ { emptyRun
                            | address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                            , duration =
                                { emptyDuration
                                    | all = 913000
                                    , mainMap = 593000
                                    , notTown = 593000
                                    , town = 320000
                                    , sides = 1000
                                }
                            , portals = 1
                            , positionEnd = 1253
                            , positionStart = 1
                            , startedAt = Time.millisToPosix 1620271058000
                            , updatedAt = Time.millisToPosix 1620271971000
                            , trialmaster =
                                [ { address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                                  , outcome = Trialmaster.Won 1000
                                  , isBossFight = True
                                  , mods =
                                        List.map Ok
                                            [ Fixture.ultimatumMod "FrostInfectionDaemon1" datamine
                                            , Fixture.ultimatumMod "GraveyardDaemon1" datamine
                                            , Fixture.ultimatumMod "GraveyardDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffBuffsExpireFaster" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffHinderedMsOnFlaskUse" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "RevenantDaemon1" datamine
                                            , Fixture.ultimatumMod "MonstersApplyRuin1" datamine
                                            ]
                                  , says = []
                                  }
                                ]
                          }
                        ]
        , test "parse trialmaster boss retreat" <|
            \_ ->
                """
2021/05/06 03:17:36 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:17:38 ] : You have entered Residence.
2021/05/06 03:17:39 ] The Trialmaster: Your luck will run out soon, challenger.
2021/05/06 03:17:39 ] The Trialmaster: You will fall to ruin.
2021/05/06 03:17:39 ] The Trialmaster: Ruin arrives suddenly.
2021/05/06 03:17:39 ] The Trialmaster: Shrapnel and shards abound.
2021/05/06 03:17:39 ] The Trialmaster: You shall suffer your own bile.
2021/05/06 03:17:39 ] The Trialmaster: Relentless assault.
2021/05/06 03:17:39 ] The Trialmaster: Be torn to shreds.
2021/05/06 03:17:39 ] The Trialmaster: Time is your enemy.
2021/05/06 03:17:39 ] The Trialmaster: Night's madness drains away all hope.
2021/05/06 03:17:39 ] The Trialmaster: Can you feel death coiling around your heart?
2021/05/06 03:17:40 ] The Trialmaster: The safe choice.
2021/05/06 03:27:30 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:27:31 ] : You have entered Stately Hideout.
2021/05/06 03:32:49 ] Connecting to instance server at 999.999.999.2:6112
2021/05/06 03:32:51 ] : You have entered Port.
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    |> List.map
                        (\r ->
                            { r
                              -- more work than it's worth to verify these
                                | npcSays = Dict.empty
                                , rootNpcs = Set.empty
                                , trialmaster =
                                    r.trialmaster
                                        |> List.map (\t -> { t | says = [] })
                            }
                        )
                    |> Expect.equal
                        [ { emptyRun
                            | address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                            , duration =
                                { emptyDuration
                                    | all = 913000
                                    , mainMap = 593000
                                    , notTown = 593000
                                    , town = 320000
                                    , sides = 1000
                                }
                            , portals = 1
                            , positionEnd = 1115
                            , positionStart = 1
                            , startedAt = Time.millisToPosix 1620271058000
                            , updatedAt = Time.millisToPosix 1620271971000
                            , trialmaster =
                                [ { address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                                  , outcome = Trialmaster.Retreated 1000
                                  , isBossFight = True
                                  , mods =
                                        List.map Ok
                                            [ Fixture.ultimatumMod "GraveyardDaemon1" datamine
                                            , Fixture.ultimatumMod "GraveyardDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffBuffsExpireFaster" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffHinderedMsOnFlaskUse" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "RevenantDaemon1" datamine
                                            , Fixture.ultimatumMod "MonstersApplyRuin1" datamine
                                            ]
                                  , says = []
                                  }
                                ]
                          }
                        ]
        , test "parse trialmaster non-boss retreat" <|
            \_ ->
                """
2021/05/06 03:17:36 ] Connecting to instance server at 999.999.999.0:6112
2021/05/06 03:17:38 ] : You have entered Residence.
2021/05/06 03:17:39 ] The Trialmaster: Your luck will run out soon, challenger.
2021/05/06 03:17:39 ] The Trialmaster: You will fall to ruin.
2021/05/06 03:17:39 ] The Trialmaster: Ruin arrives suddenly.
2021/05/06 03:17:39 ] The Trialmaster: Shrapnel and shards abound.
2021/05/06 03:17:39 ] The Trialmaster: You shall suffer your own bile.
2021/05/06 03:17:39 ] The Trialmaster: Relentless assault.
2021/05/06 03:17:39 ] The Trialmaster: Be torn to shreds.
2021/05/06 03:17:39 ] The Trialmaster: Time is your enemy.
2021/05/06 03:17:39 ] The Trialmaster: Night's madness drains away all hope.
2021/05/06 03:17:40 ] The Trialmaster: The safe choice.
2021/05/06 03:27:30 ] Connecting to instance server at 999.999.999.1:6112
2021/05/06 03:27:31 ] : You have entered Stately Hideout.
2021/05/06 03:32:49 ] Connecting to instance server at 999.999.999.2:6112
2021/05/06 03:32:51 ] : You have entered Port.
                """
                    |> crlfFix
                    |> Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0
                    |> .runs
                    |> List.map
                        (\r ->
                            { r
                              -- more work than it's worth to verify these
                                | npcSays = Dict.empty
                                , rootNpcs = Set.empty
                                , trialmaster =
                                    r.trialmaster
                                        |> List.map (\t -> { t | says = [] })
                            }
                        )
                    |> Expect.equal
                        [ { emptyRun
                            | address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                            , duration =
                                { emptyDuration
                                    | all = 913000
                                    , mainMap = 593000
                                    , notTown = 593000
                                    , town = 320000
                                    , sides = 1000
                                }
                            , portals = 1
                            , positionEnd = 1030
                            , positionStart = 1
                            , startedAt = Time.millisToPosix 1620271058000
                            , updatedAt = Time.millisToPosix 1620271971000
                            , trialmaster =
                                [ { address = address "999.999.999.0:6112" "MapWorldsResidence" "Residence"
                                  , outcome = Trialmaster.Retreated 1000
                                  , isBossFight = False
                                  , mods =
                                        List.map Ok
                                            [ Fixture.ultimatumMod "GraveyardDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffBuffsExpireFaster" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "PlayerDebuffHinderedMsOnFlaskUse" datamine
                                            , Fixture.ultimatumMod "SawbladeDaemon1" datamine
                                            , Fixture.ultimatumMod "RevenantDaemon1" datamine
                                            , Fixture.ultimatumMod "MonstersApplyRuin1" datamine
                                            ]
                                  , says = []
                                  }
                                ]
                          }
                        ]
        ]
