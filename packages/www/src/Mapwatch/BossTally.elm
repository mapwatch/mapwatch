module Mapwatch.BossTally exposing
    ( BossMark
    , BossTally
    , UberBossEntry
    , aggregate
    , fromMapRun
    , groupAll
    , groupConquerors
    , groupLesserEldritch
    , groupPinnacle
    , groupShaperGuardians
    , groupUber
    )

import Dict exposing (Dict)
import Duration exposing (Millis)
import Mapwatch.BossEntry as BossEntry exposing (BossEntry, Progress)
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.Datamine.NpcId as NpcId
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Time exposing (Posix)


type alias BossTally =
    { atziri : UberBossEntry
    , uberelder : UberBossEntry
    , venarius : UberBossEntry
    , maven : UberBossEntry
    , sirus : UberBossEntry
    , exarch : UberBossEntry
    , eater : UberBossEntry

    -- conquerors
    , baran : BossEntry
    , veritania : BossEntry
    , alhezmin : BossEntry
    , drox : BossEntry

    -- siege
    , blackstar : BossEntry
    , hunger : BossEntry

    -- shaper, elder, guardians
    -- elder is quiet, but maven makes it trackable
    -- cannot track elder guardians at all: we can't even identify their maps, much less completion
    , shaper : BossEntry
    , elder : BossEntry
    , shaperChimera : BossEntry
    , shaperHydra : BossEntry
    , shaperMinotaur : BossEntry
    , shaperPhoenix : BossEntry

    -- TODO izaro + uber izaro?
    -- TODO bestiary?
    -- TODO breachlords
    -- TODO synthesis "guardians"
    -- TODO catarina
    }


type alias UberBossEntry =
    { standard : BossEntry
    , uber : BossEntry
    }


type BossId
    = Atziri Bool
    | UberElder Bool
    | Venarius Bool
    | Sirus Bool
    | Maven Bool
    | Eater Bool
    | Exarch Bool
    | BlackStar
    | Hunger
    | Shaper
    | Elder
    | Baran
    | Veritania
    | AlHezmin
    | Drox
    | ShaperMinotaur
    | ShaperChimera
    | ShaperPhoenix
    | ShaperHydra


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


empty : BossTally
empty =
    let
        e : BossEntry
        e =
            BossEntry.Unvisited

        ue : UberBossEntry
        ue =
            UberBossEntry e e
    in
    BossTally ue ue ue ue ue ue ue e e e e e e e e e e e e


groupShaperGuardians : BossTally -> List BossEntry
groupShaperGuardians t =
    [ t.shaperChimera, t.shaperHydra, t.shaperMinotaur, t.shaperPhoenix ]


groupConquerors : BossTally -> List BossEntry
groupConquerors t =
    [ t.baran, t.drox, t.veritania, t.alhezmin ]


groupLesserEldritch : BossTally -> List BossEntry
groupLesserEldritch t =
    [ t.shaper, t.elder, t.blackstar, t.hunger ]


groupPinnacle : BossTally -> List BossEntry
groupPinnacle t =
    [ t.exarch.standard, t.eater.standard, t.maven.standard, t.venarius.standard, t.sirus.standard, t.uberelder.standard ]


groupUber : BossTally -> List BossEntry
groupUber t =
    [ t.exarch.uber, t.eater.uber, t.maven.uber, t.venarius.uber, t.sirus.uber, t.uberelder.uber, t.atziri.uber ]


groupAll : BossTally -> List BossEntry
groupAll t =
    [ groupUber, groupPinnacle, groupLesserEldritch, groupConquerors, groupShaperGuardians ]
        |> List.concatMap (\g -> g t)


aggregate : List BossMark -> BossTally
aggregate =
    List.foldl applyMark empty


fromMapRun : RawMapRun -> WorldArea -> Maybe BossMark
fromMapRun run w =
    toMarkCompletion run w
        |> Maybe.map
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


toMarkCompletion : RawMapRun -> WorldArea -> Maybe ( BossId, Outcome )
toMarkCompletion run w =
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
                ( Shaper
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


countTextId : (String -> Bool) -> String -> RawMapRun -> Int
countTextId pred npcId run =
    run.npcSays
        |> Dict.get npcId
        |> Maybe.withDefault []
        |> List.filterMap (.says >> .textId)
        |> List.map pred
        |> List.filter identity
        |> List.length


applyMark : BossMark -> BossTally -> BossTally
applyMark mark tally =
    case mark.boss of
        Atziri isUber ->
            { tally | atziri = tally.atziri |> applyUberEntry isUber mark }

        UberElder isUber ->
            { tally | uberelder = tally.uberelder |> applyUberEntry isUber mark }

        Venarius isUber ->
            { tally | venarius = tally.venarius |> applyUberEntry isUber mark }

        Maven isUber ->
            { tally | maven = tally.maven |> applyUberEntry isUber mark }

        Sirus isUber ->
            { tally | sirus = tally.sirus |> applyUberEntry isUber mark }

        Exarch isUber ->
            { tally | exarch = tally.exarch |> applyUberEntry isUber mark }

        Eater isUber ->
            { tally | eater = tally.eater |> applyUberEntry isUber mark }

        BlackStar ->
            { tally | blackstar = tally.blackstar |> applyEntry mark }

        Hunger ->
            { tally | hunger = tally.hunger |> applyEntry mark }

        Shaper ->
            { tally | shaper = tally.shaper |> applyEntry mark }

        Elder ->
            { tally | elder = tally.elder |> applyEntry mark }

        Baran ->
            { tally | baran = tally.baran |> applyEntry mark }

        Veritania ->
            { tally | veritania = tally.veritania |> applyEntry mark }

        AlHezmin ->
            { tally | alhezmin = tally.alhezmin |> applyEntry mark }

        Drox ->
            { tally | drox = tally.drox |> applyEntry mark }

        ShaperMinotaur ->
            { tally | shaperMinotaur = tally.shaperMinotaur |> applyEntry mark }

        ShaperChimera ->
            { tally | shaperChimera = tally.shaperChimera |> applyEntry mark }

        ShaperPhoenix ->
            { tally | shaperPhoenix = tally.shaperPhoenix |> applyEntry mark }

        ShaperHydra ->
            { tally | shaperHydra = tally.shaperHydra |> applyEntry mark }


applyUberEntry : Bool -> BossMark -> UberBossEntry -> UberBossEntry
applyUberEntry isUber mark entry =
    if isUber then
        { entry | uber = applyEntry mark entry.uber }

    else
        { entry | standard = applyEntry mark entry.standard }


markToEntry : BossMark -> BossEntry
markToEntry mark =
    let
        visited =
            { achievedAt = mark.startedAt, count = 1 }
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
                        { achievedAt = completeAt, count = 1, victory = victory }
                in
                if mark.logouts <= 0 then
                    BossEntry.Logoutless { achievedAt = completeAt, count = 1, deathless = deathless }

                else
                    BossEntry.Deathless deathless

            else
                BossEntry.Victory victory

        _ ->
            BossEntry.Visited visited


applyEntry : BossMark -> BossEntry -> BossEntry
applyEntry mark =
    BossEntry.mergePair (markToEntry mark)
