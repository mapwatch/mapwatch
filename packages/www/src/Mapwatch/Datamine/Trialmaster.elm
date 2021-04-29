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
    if String.startsWith "TrialmasterMoodPlayerWon" id || String.startsWith "TrialmasterTutorialFullWin" id then
        Just Won

    else if String.startsWith "TrialmasterMoodPlayerLost" id || String.startsWith "TrialmasterTutorialPlayerLoses" id then
        Just Lost

    else if
        (String.startsWith "TrialmasterPlayerTookReward" id
            -- `PlayerTookRewardLastTime` is a first message, not a last message
            && not (String.startsWith "TrialmasterPlayerTookRewardLastTime" id)
        )
            || String.startsWith "TrialmasterTutorialStop" id
    then
        Just Retreated

    else
        Nothing


idPrefixesToMods : List ( String, String )
idPrefixesToMods =
    -- NpcTextId prefix to mod id. We don't care about mod tier (yet).
    -- TODO can this mapping be datamined, instead of figured out here? probably not...
    [ ( "ChasingMiasma", "ChaosCloudDaemon1" )
    , ( "StormRunes", "LightningRuneDaemon1" )
    , ( "FireCrystals", "FlamespitterDaemon1" )
    , ( "IceSpines", "FrostInfectionDaemon1" )
    , ( "UnhallowedPatches", "GraveyardDaemon1" )
    , ( "RuinHunter", "RevenantDaemon1" )
    , ( "Shardspeaker", "SawbladeDaemon1" )
    , ( "Blades", "SawbladeDaemon1" )
    , ( "PhysicalTotem", "PhysTotemDaemon" )
    , ( "FireTotem", "EleTotemDaemon" )
    , ( "SmallerArena", "Radius1" )
    , ( "FailAtFiveRuin", "MonstersApplyRuin1" )
    , ( "FailAtTenRuin", "MonstersApplyRuin1" )
    , ( "TwoTypesApplyRuin", "MonstersApplyRuin1" )
    , ( "ReducedRecovery", "PlayerDebuffRecoveryReduction1" )
    , ( "LessAOELessProjSpeed", "PlayerDebuffAreaAndProjectileSpeed" )
    , ( "BuffsExpireFaster", "PlayerDebuffBuffsExpireFaster" )
    , ( "DiminishRecovery", "PlayerDebuffCooldownSpeed" )
    , ( "EscalatingVuln", "PlayerDebuffIncreasingVulnerability" )
    , ( "MonstersSpeedUp", "MonsterBuffAcceleratingSpeed" )
    , ( "Voidspeaker", "MonsterBuffNonChaosDamageToAddAsChaosDamage" )
    , ( "UnluckyCrit", "PlayerDebuffExtraCriticalRolls" )
    , ( "FlasksHinder", "PlayerDebuffHinderedMsOnFlaskUse" )
    , ( "FlasksCancel", "PlayerDebuffCancelFlaskEffectOnFlaskUse" )
    , ( "CurseReflect", "PlayerDebuffCursesandNonDamagingAilmentsReflectedToSelf" )
    , ( "ManaCostAsDamage", "PlayerDebuffSelfLightningDamageOnSkillUseManaSpentOnCostLow" )
    , ( "ReflectProjectiles", "PlayerDebuffRandomProjectileDirection" )
    , ( "YourAurasAffectEnemies", "PlayerDebuffAurasAffectAllies" )
    , ( "DealNoDamageSometimes", "PlayerDebuffUltimatumDealNoDamageFor2SecondEvery8Seconds" )
    , ( "LoseCharges", "PlayerDebuffUltimatumLoseChargesEverySecond" )
    ]
        -- common id prefix
        |> List.map (Tuple.mapFirst ((++) roundPrefix))


roundPrefix : String
roundPrefix =
    "TrialmasterChallengeChoiceMade"
