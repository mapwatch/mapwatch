module Mapwatch.BossMark exposing
    ( BossId(..)
    , BossMark
    , apply
    , fromMapRun
    )

import Dict
import Mapwatch.BossEntry as BossEntry exposing (BossEntry)
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.Datamine.NpcId as NpcId
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Time exposing (Posix)


type alias BossMark =
    { boss : BossId
    , completed : Outcome
    , deaths : Int
    , logouts : Int
    , startedAt : Posix
    }


type Outcome
    = UnknownOutcome -- possible for quiet bosses that require maven for tracking
    | Incomplete
    | Complete Posix


type BossId
    = Atziri Bool
    | UberElder Bool
    | Shaper Bool
    | Venarius Bool
    | Sirus Bool
    | Maven Bool
    | Eater Bool
    | Exarch Bool
    | BlackStar
    | Hunger
    | Elder
    | Baran
    | Veritania
    | AlHezmin
    | Drox
    | ShaperMinotaur
    | ShaperChimera
    | ShaperPhoenix
    | ShaperHydra


fromMapRun : RawMapRun -> WorldArea -> Maybe BossMark
fromMapRun run w =
    Maybe.map
        (\( id, completed ) ->
            let
                outcomeAt : Posix
                outcomeAt =
                    case completed of
                        Complete at ->
                            at

                        _ ->
                            RawMapRun.updatedAt run

                countDuring : List Posix -> Int
                countDuring =
                    List.map Time.posixToMillis
                        >> List.filter (\t -> t >= Time.posixToMillis run.startedAt && t <= Time.posixToMillis outcomeAt)
                        >> List.length
            in
            { boss = id
            , completed = completed
            , deaths = run.deathsAt |> countDuring
            , logouts = run.portalsAt |> countDuring
            , startedAt = run.startedAt
            }
        )
        (toCompletion run w)


toCompletion : RawMapRun -> WorldArea -> Maybe ( BossId, Outcome )
toCompletion run w =
    let
        is85 : Bool
        is85 =
            Maybe.withDefault 0 run.level >= 85
    in
    case w.id of
        "MapAtziri1" ->
            -- apex of sacrifice: tracking victory is impossible :(
            Just ( Atziri False, UnknownOutcome )

        "MapAtziri2" ->
            -- alluring abyss: tracking victory is only possible with the maven
            Just
                ( Atziri True
                , run |> outcomeMavenVictoryTextId
                )

        "MapWorldsElderArena" ->
            -- tracking victory is only possible with the maven
            Just
                ( Elder
                , run |> outcomeMavenVictoryTextId
                )

        "MapWorldsElderArenaUber" ->
            -- tracking victory is only possible with the maven
            Just
                ( UberElder is85
                , run |> outcomeMavenVictoryTextId
                )

        "Synthesis_MapBoss" ->
            Just
                ( Venarius is85
                , run |> outcomeTextId ((==) "VenariusBossFightDepart") NpcId.venarius
                )

        "AtlasExilesBoss5" ->
            Just
                ( Sirus is85
                , run |> outcomeTextId (\s -> s == "SirusSimpleDeathLine" || String.startsWith "SirusComplexDeathLine" s) NpcId.sirus
                )

        "MavenBoss" ->
            Just
                ( Maven is85
                , run |> outcomeTextId (\s -> String.startsWith "MavenFinalFightRealises" s || String.startsWith "MavenFinalFightRepeatedRealises" s) NpcId.maven
                )

        "MapWorldsShapersRealm" ->
            Just
                ( Shaper is85
                  -- shaper retreats 3 times, saying similar defeat text each time. The third one is our completion signal
                , getTextIdsOrDefault
                    { missingNpcId = Incomplete
                    , missingTextId = Incomplete
                    , success =
                        \e es ->
                            if List.length (e :: es) >= 3 then
                                e :: es |> List.reverse |> List.head |> Maybe.withDefault e |> .date |> Complete

                            else
                                Incomplete
                    }
                    (String.startsWith "ShaperBanish")
                    NpcId.shaper
                    run
                )

        "MapWorldsPrimordialBoss1" ->
            Just
                ( Hunger
                , run |> outcomeTextId (String.startsWith "DoomBossDefeated") NpcId.hunger
                )

        "MapWorldsPrimordialBoss2" ->
            Just
                ( BlackStar
                , run |> outcomeTextId (String.startsWith "TheBlackStarDeath") NpcId.blackstar
                )

        "MapWorldsPrimordialBoss3" ->
            Just
                ( Exarch is85
                , run |> outcomeTextId (String.startsWith "CleansingFireDefeated") NpcId.exarch
                )

        "MapWorldsPrimordialBoss4" ->
            Just
                ( Eater is85
                , run |> outcomeTextId (String.startsWith "ConsumeBossDefeated") NpcId.eater
                )

        "MapWorldsMinotaur" ->
            Just
                ( ShaperMinotaur
                , run |> outcomeTextId ((==) "ShaperAtlasMapDrops") NpcId.shaper
                )

        "MapWorldsChimera" ->
            Just
                ( ShaperChimera
                , run |> outcomeTextId ((==) "ShaperAtlasMapDrops") NpcId.shaper
                )

        "MapWorldsPhoenix" ->
            Just
                ( ShaperPhoenix
                , run |> outcomeTextId ((==) "ShaperAtlasMapDrops") NpcId.shaper
                )

        "MapWorldsHydra" ->
            Just
                ( ShaperHydra
                , run |> outcomeTextId ((==) "ShaperAtlasMapDrops") NpcId.shaper
                )

        _ ->
            let
                conqNpcs =
                    [ ( Baran, NpcId.baran, [ "BaranFourStoneDeath", "BaranFourStoneStoryDeath" ] )
                    , ( AlHezmin, NpcId.alHezmin, [ "AlHezminFourStoneDeath" ] )
                    , ( Veritania, NpcId.veritania, [ "VeritaniaFourStoneDeath" ] )
                    , ( Drox, NpcId.drox, [ "DroxFourStoneDeath" ] )
                    ]
            in
            case conqNpcs |> List.filter (\( _, npcId, _ ) -> run.npcSays |> Dict.member npcId) of
                ( bossId, npcId, victoryPrefix ) :: _ ->
                    Just
                        ( bossId
                        , run |> outcomeTextId (\s -> List.any (\v -> String.startsWith v s) victoryPrefix) npcId
                        )

                [] ->
                    Nothing


isMavenVictoryTextId : String -> Bool
isMavenVictoryTextId s =
    -- big bosses: shaper, elder...
    String.startsWith "MavenTier5FirstOffAtlasBossVictory" s
        || String.startsWith "MavenTier5OffAtlasBossVictory" s
        || String.startsWith "MavenTier5OffAtlasInvitation" s
        -- map bosses
        || String.startsWith "MavenTier5BossVictory" s
        || String.startsWith "MavenTier5Invitation" s


outcomeMavenVictoryTextId : RawMapRun -> Outcome
outcomeMavenVictoryTextId =
    getTextIdOrDefault { missingNpcId = UnknownOutcome, missingTextId = Incomplete, success = .date >> Complete } isMavenVictoryTextId NpcId.maven


outcomeTextId : (String -> Bool) -> String -> RawMapRun -> Outcome
outcomeTextId =
    getTextIdOrDefault { missingNpcId = Incomplete, missingTextId = Incomplete, success = .date >> Complete }


hasTextId : (String -> Bool) -> String -> RawMapRun -> Bool
hasTextId =
    getTextIdOrDefault { missingNpcId = False, missingTextId = False, success = always True }


getTextId : (String -> Bool) -> String -> RawMapRun -> Maybe RawMapRun.NpcEncounter
getTextId =
    getTextIdOrDefault { missingNpcId = Nothing, missingTextId = Nothing, success = Just }


getTextIdOrDefault : { missingNpcId : a, missingTextId : a, success : RawMapRun.NpcEncounter -> a } -> (String -> Bool) -> String -> RawMapRun -> a
getTextIdOrDefault result =
    getTextIdsOrDefault
        { missingNpcId = result.missingNpcId
        , missingTextId = result.missingTextId
        , success = \e _ -> result.success e
        }


getTextIdsOrDefault : { missingNpcId : a, missingTextId : a, success : RawMapRun.NpcEncounter -> List RawMapRun.NpcEncounter -> a } -> (String -> Bool) -> String -> RawMapRun -> a
getTextIdsOrDefault result pred npcId run =
    case run.npcSays |> Dict.get npcId of
        Nothing ->
            result.missingNpcId

        Just npcTexts ->
            case npcTexts |> List.filter (.says >> .textId >> Maybe.map pred >> Maybe.withDefault False) of
                head :: tail ->
                    result.success head tail

                [] ->
                    result.missingTextId


toEntry : BossMark -> BossEntry
toEntry mark =
    let
        visited =
            { achievedAt = mark.startedAt }
    in
    case mark.completed of
        Complete completeAt ->
            let
                victory =
                    { achievedAt = completeAt, count = 1, visited = visited }
            in
            if mark.deaths <= 0 then
                let
                    deathless =
                        { achievedAt = completeAt, victory = victory }
                in
                if mark.logouts <= 0 then
                    BossEntry.Logoutless { achievedAt = completeAt, deathless = deathless }

                else
                    BossEntry.Deathless deathless

            else
                BossEntry.Victory victory

        _ ->
            BossEntry.Visited visited


apply : BossMark -> BossEntry -> BossEntry
apply mark =
    BossEntry.mergePair (toEntry mark)
