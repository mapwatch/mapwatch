module Mapwatch.Datamine.Trialmaster exposing (Index, Outcome(..), npcTextIndex, roundPrefix)

-- import Mapwatch.MapRun.Trialmaster as Trialmaster exposing (Outcome(..))

import Dict exposing (Dict)
import List.Extra


type Outcome
    = Won
    | Lost
    | Retreated
    | Abandoned


type alias Index =
    { outcomes : Dict String Outcome
    , modIds : Dict String String
    }


npcTextIndex : List String -> Index
npcTextIndex =
    List.filter (String.startsWith "Trialmaster") >> npcTextIndex_


npcTextIndex_ : List String -> Index
npcTextIndex_ ids =
    { outcomes =
        ids
            |> List.filterMap (\id -> id |> outcomeFromId |> Maybe.map (Tuple.pair id))
            |> Dict.fromList
    , modIds =
        ids
            |> List.filterMap (\id -> id |> modFromId |> Maybe.map (Tuple.pair id))
            |> Dict.fromList
    }


modFromId : String -> Maybe String
modFromId id =
    idPrefixesToMods
        |> List.Extra.find (Tuple.first >> (\prefix -> String.startsWith prefix id))
        |> Maybe.map Tuple.second


outcomeFromId : String -> Maybe Outcome
outcomeFromId id =
    if String.startsWith "TrialmasterMoodPlayerWon" id then
        Just Won

    else if String.startsWith "TrialmasterMoodPlayerLost" id then
        Just Lost

    else if String.startsWith "TrialmasterPlayerTookReward" id || String.startsWith "TrialmasterTutorialStop" id then
        Just Retreated

    else
        Nothing


idPrefixesToMods : List ( String, String )
idPrefixesToMods =
    -- NpcTextId prefix to mod id. We don't care about mod tier (yet).
    -- TODO is there a datamineable map for this mapping? probably not...
    [ ( "ChasingMiasma", "ChaosCloudDaemon1" )
    , ( "StormRunes", "LightningRuneDaemon1" )
    , ( "FireCrystals", "FlamespitterDaemon1" )
    , ( "IceSpines", "FrostInfectionDaemon1" )
    , ( "UnhallowedPatches", "GraveyardDaemon1" )
    , ( "RuinHunter", "RevenantDaemon1" )

    -- guess
    , ( "Shardspeaker", "SawbladeDaemon1" )

    -- guess
    , ( "Blades", "SawbladeDaemon1" )
    , ( "PhysicalTotem", "PhysTotemDaemon" )
    , ( "FireTotem", "EleTotemDaemon" )
    , ( "SmallerArena", "Radius1" )
    , ( "FailAtFiveRuin", "MonstersApplyRuin1" )
    , ( "FailAtTenRuin", "MonstersApplyRuin1" )

    -- Guess
    , ( "ReducedRecovery", "PlayerDebuffRecoveryReduction1" )
    , ( "ReflectProjectiles", "PlayerDebuffAreaAndProjectileSpeed" )
    , ( "BuffsExpireFaster", "PlayerDebuffBuffsExpireFaster" )

    -- Guess
    , ( "DiminishRecovery", "PlayerDebuffCooldownSpeed" )
    , ( "EscalatingVuln", "PlayerDebuffIncreasingVulnerability" )
    , ( "MonstersSpeedUp", "MonsterBuffAcceleratingSpeed" )

    -- , ( ";", "MonsterBuffNonChaosDamageToAddAsChaosDamage" )
    -- guess
    , ( "UnluckyCrit", "PlayerDebuffExtraCriticalRolls" )
    , ( "FlasksHinder", "PlayerDebuffHinderedMsOnFlaskUse" )
    , ( "FlasksCancel", "PlayerDebuffCancelFlaskEffectOnFlaskUse" )
    , ( "CurseReflect", "PlayerDebuffCursesandNonDamagingAilmentsReflectedToSelf" )
    , ( "ManaCostAsDamage", "PlayerDebuffSelfLightningDamageOnSkillUseManaSpentOnCostLow" )
    , ( "ReflectProjectiles", "PlayerDebuffRandomProjectileDirection" )
    , ( "YourAurasAffectEnemies", "PlayerDebuffAurasAffectAllies" )
    , ( "DealNoDamageSometimes", "PlayerDebuffUltimatumDealNoDamageFor2SecondEvery8Seconds" )

    -- guess
    , ( "LoseCharges", "PlayerDebuffUltimatumLoseChargesEverySecond" )
    ]
        -- common id prefix
        |> List.map (Tuple.mapFirst ((++) roundPrefix))


roundPrefix : String
roundPrefix =
    "TrialmasterChallengeChoiceMade"



--modVoicesOld : List String
--modVoicesOld =
--    [ "FailAtTenRuin"
--    , "RuinHunter"
--    , "FailAtFiveRuin"
--    , "TwoTypesApplyRuin"
--    , "UnhallowedPatches"
--    , "BeforeACertainTime"
--    , "BuffsExpireFaster"
--    , "TimeIsShorter"
--    , "LoseCharges"
--    , "EscalatingVuln"
--    , "VulnStartsTenPercent"
--    , "VulnEscalatesFaster"
--    , "MonstersSpeedUp"
--    , "MonstersStartAtTwentySpeed"
--    , "MonstersSpeedUpFaster"
--    , "DiminishRecovery"
--    , "DealNoDamageSometimes"
--    , "ChasingMiasma"
--    , "FireCrystals"
--    , "UnusedCold"
--    , "StormRunes"
--    , "IceSpines"
--    , "Flamespeaker"
--    , "FireTotem"
--    , "Frostspeaker"
--    , "Stormspeaker"
--    , "Voidspeaker"
--    , "PhysicalTotem"
--    , "Shardspeaker"
--    , "Blades"
--    , "SpeakerShorterDelay"
--    , "ChainedBeasts"
--    , "SmallerArena"
--    , "ReducedRecovery"
--    , "FlasksHinder"
--    , "CurseReflect"
--    , "ManaCostAsDamage"
--    , "FlasksCancelEachOther"
--    , "LessAOELessProjSpeed"
--    , "UnluckyCrit"
--    , "ReflectProjectiles"
--    , "YourAurasAffectEnemies"
--    ]
