module Mapwatch.BossTally exposing
    ( BossTally
    , UberBossEntry
    , aggregate
    , groupAll
    , groupConquerors
    , groupLesserEldritch
    , groupPinnacle
    , groupShaperGuardians
    , groupUber
    )

import Mapwatch.BossEntry as BossEntry exposing (BossEntry)
import Mapwatch.BossMark as BossMark exposing (BossId(..), BossMark)


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
            { tally | blackstar = tally.blackstar |> BossMark.apply mark }

        Hunger ->
            { tally | hunger = tally.hunger |> BossMark.apply mark }

        Shaper ->
            { tally | shaper = tally.shaper |> BossMark.apply mark }

        Elder ->
            { tally | elder = tally.elder |> BossMark.apply mark }

        Baran ->
            { tally | baran = tally.baran |> BossMark.apply mark }

        Veritania ->
            { tally | veritania = tally.veritania |> BossMark.apply mark }

        AlHezmin ->
            { tally | alhezmin = tally.alhezmin |> BossMark.apply mark }

        Drox ->
            { tally | drox = tally.drox |> BossMark.apply mark }

        ShaperMinotaur ->
            { tally | shaperMinotaur = tally.shaperMinotaur |> BossMark.apply mark }

        ShaperChimera ->
            { tally | shaperChimera = tally.shaperChimera |> BossMark.apply mark }

        ShaperPhoenix ->
            { tally | shaperPhoenix = tally.shaperPhoenix |> BossMark.apply mark }

        ShaperHydra ->
            { tally | shaperHydra = tally.shaperHydra |> BossMark.apply mark }


applyUberEntry : Bool -> BossMark -> UberBossEntry -> UberBossEntry
applyUberEntry isUber mark entry =
    if isUber then
        { entry | uber = entry.uber |> BossMark.apply mark }

    else
        { entry | standard = entry.standard |> BossMark.apply mark }
