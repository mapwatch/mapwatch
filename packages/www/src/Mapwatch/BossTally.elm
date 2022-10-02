module Mapwatch.BossTally exposing
    ( BossTally
    , Group(..)
    , UberBossEntry
    , aggregate
    , entry
    , groupBosses
    , groupProgress
    , groups
    , jsonDecode
    , jsonEncode
    , toEntries
    , toEntryGroups
    )

import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
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
    , shaper : UberBossEntry

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
    , elder : BossEntry
    , shaperChimera : BossEntry
    , shaperHydra : BossEntry
    , shaperMinotaur : BossEntry
    , shaperPhoenix : BossEntry

    -- breach
    , breachXoph : BossEntry
    , breachTul : BossEntry
    , breachEsh : BossEntry
    , breachUul : BossEntry
    , breachChayula : BossEntry

    -- TODO izaro + uber izaro?
    -- TODO bestiary?
    -- TODO synthesis "guardians"
    , mastermind : BossEntry
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
    BossTally ue ue ue ue ue ue ue ue e e e e e e e e e e e e e e e e e


type Group
    = All
    | Breachlords
    | ShaperGuardians
    | Conquerors
    | LesserEldritches
    | Pinnacles
    | Ubers


groups : List Group
groups =
    [ Breachlords, ShaperGuardians, Conquerors, LesserEldritches, Pinnacles, Ubers
    ]


uberables : List (Bool -> BossId)
uberables =
    [ Exarch, Eater, Maven, Venarius, Sirus, UberElder, Shaper ]


groupBosses : Group -> List BossId
groupBosses g =
    case g of
        All ->
            groups |> List.concatMap groupBosses

        Ubers ->
            (uberables |> List.map (\u -> u True)) ++ [ Atziri True ]

        Pinnacles ->
            uberables |> List.map (\u -> u False)

        LesserEldritches ->
            [ Elder, BlackStar, Hunger, Mastermind ]

        Conquerors ->
            [ Baran, AlHezmin, Veritania, Drox ]

        Breachlords ->
            [ BreachXoph, BreachTul, BreachEsh, BreachUul, BreachChayula ]

        ShaperGuardians ->
            [ ShaperChimera, ShaperHydra, ShaperPhoenix, ShaperMinotaur ]


groupProgress : Group -> BossTally -> BossEntry.Progress
groupProgress g t =
    g
        |> groupBosses
        |> List.map (\b -> entry b t)
        |> BossEntry.progressList


toEntryGroups : BossTally -> List ( Group, List ( BossId, BossEntry ) )
toEntryGroups t =
    groups |> List.map (\g -> ( g, g |> groupBosses |> List.map (\b -> ( b, entry b t )) ))


toEntries : BossTally -> List ( BossId, BossEntry )
toEntries =
    toEntryGroups >> List.concatMap Tuple.second


aggregate : List BossMark -> BossTally
aggregate =
    List.foldl applyMark empty


entry : BossId -> BossTally -> BossEntry
entry id t =
    case id of
        Atziri isUber ->
            entryUber isUber t.atziri

        UberElder isUber ->
            entryUber isUber t.uberelder

        Shaper isUber ->
            entryUber isUber t.shaper

        Venarius isUber ->
            entryUber isUber t.venarius

        Maven isUber ->
            entryUber isUber t.maven

        Sirus isUber ->
            entryUber isUber t.sirus

        Exarch isUber ->
            entryUber isUber t.exarch

        Eater isUber ->
            entryUber isUber t.eater

        BlackStar ->
            t.blackstar

        Hunger ->
            t.hunger

        Elder ->
            t.elder

        Baran ->
            t.baran

        Veritania ->
            t.veritania

        AlHezmin ->
            t.alhezmin

        Drox ->
            t.drox

        ShaperMinotaur ->
            t.shaperMinotaur

        ShaperChimera ->
            t.shaperChimera

        ShaperPhoenix ->
            t.shaperPhoenix

        ShaperHydra ->
            t.shaperHydra

        BreachXoph ->
            t.breachXoph

        BreachTul ->
            t.breachTul

        BreachEsh ->
            t.breachEsh

        BreachUul ->
            t.breachUul

        BreachChayula ->
            t.breachChayula

        Mastermind ->
            t.mastermind


entryUber : Bool -> UberBossEntry -> BossEntry
entryUber isUber =
    if isUber then
        .uber

    else
        .standard


applyMark : BossMark -> BossTally -> BossTally
applyMark mark tally =
    case mark.boss of
        Atziri isUber ->
            { tally | atziri = tally.atziri |> applyUberEntry isUber mark }

        UberElder isUber ->
            { tally | uberelder = tally.uberelder |> applyUberEntry isUber mark }

        Shaper isUber ->
            { tally | shaper = tally.shaper |> applyUberEntry isUber mark }

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

        BreachXoph ->
            { tally | breachXoph = tally.breachXoph |> BossMark.apply mark }

        BreachTul ->
            { tally | breachTul = tally.breachTul |> BossMark.apply mark }

        BreachEsh ->
            { tally | breachEsh = tally.breachEsh |> BossMark.apply mark }

        BreachUul ->
            { tally | breachUul = tally.breachUul |> BossMark.apply mark }

        BreachChayula ->
            { tally | breachChayula = tally.breachChayula |> BossMark.apply mark }

        Mastermind ->
            { tally | mastermind = tally.mastermind |> BossMark.apply mark }


applyUberEntry : Bool -> BossMark -> UberBossEntry -> UberBossEntry
applyUberEntry isUber mark e =
    if isUber then
        { e | uber = e.uber |> BossMark.apply mark }

    else
        { e | standard = e.standard |> BossMark.apply mark }



-- json encode/decode


jsonEncode : BossTally -> D.Value
jsonEncode t =
    E.object
        [ ( "atziri", t.atziri |> jsonEncodeUberEntry )
        , ( "uberelder", t.uberelder |> jsonEncodeUberEntry )
        , ( "venarius", t.venarius |> jsonEncodeUberEntry )
        , ( "maven", t.maven |> jsonEncodeUberEntry )
        , ( "sirus", t.sirus |> jsonEncodeUberEntry )
        , ( "exarch", t.exarch |> jsonEncodeUberEntry )
        , ( "eater", t.eater |> jsonEncodeUberEntry )
        , ( "shaper", t.shaper |> jsonEncodeUberEntry )
        , ( "baran", t.baran |> BossEntry.jsonEncode )
        , ( "veritania", t.veritania |> BossEntry.jsonEncode )
        , ( "alhezmin", t.alhezmin |> BossEntry.jsonEncode )
        , ( "drox", t.drox |> BossEntry.jsonEncode )
        , ( "blackstar", t.blackstar |> BossEntry.jsonEncode )
        , ( "hunger", t.hunger |> BossEntry.jsonEncode )
        , ( "elder", t.elder |> BossEntry.jsonEncode )
        , ( "shaperChimera", t.shaperChimera |> BossEntry.jsonEncode )
        , ( "shaperHydra", t.shaperHydra |> BossEntry.jsonEncode )
        , ( "shaperMinotaur", t.shaperMinotaur |> BossEntry.jsonEncode )
        , ( "shaperPhoenix", t.shaperPhoenix |> BossEntry.jsonEncode )
        , ( "breachXoph", t.breachXoph |> BossEntry.jsonEncode )
        , ( "breachTul", t.breachTul |> BossEntry.jsonEncode )
        , ( "breachEsh", t.breachEsh |> BossEntry.jsonEncode )
        , ( "breachUul", t.breachUul |> BossEntry.jsonEncode )
        , ( "breachChayula", t.breachChayula |> BossEntry.jsonEncode )
        , ( "mastermind", t.mastermind |> BossEntry.jsonEncode )
        ]


jsonEncodeUberEntry : UberBossEntry -> D.Value
jsonEncodeUberEntry e =
    E.object
        [ ( "standard", e.standard |> BossEntry.jsonEncode )
        , ( "uber", e.uber |> BossEntry.jsonEncode )
        ]


jsonDecode : D.Decoder BossTally
jsonDecode =
    D.succeed BossTally
        |> P.required "atziri" jsonDecodeUberEntry
        |> P.required "uberelder" jsonDecodeUberEntry
        |> P.required "venarius" jsonDecodeUberEntry
        |> P.required "maven" jsonDecodeUberEntry
        |> P.required "sirus" jsonDecodeUberEntry
        |> P.required "exarch" jsonDecodeUberEntry
        |> P.required "eater" jsonDecodeUberEntry
        |> P.required "shaper" jsonDecodeUberEntry
        |> P.required "baran" BossEntry.jsonDecode
        |> P.required "veritania" BossEntry.jsonDecode
        |> P.required "alhezmin" BossEntry.jsonDecode
        |> P.required "drox" BossEntry.jsonDecode
        |> P.required "blackstar" BossEntry.jsonDecode
        |> P.required "hunger" BossEntry.jsonDecode
        |> P.required "elder" BossEntry.jsonDecode
        |> P.required "shaperChimera" BossEntry.jsonDecode
        |> P.required "shaperHydra" BossEntry.jsonDecode
        |> P.required "shaperMinotaur" BossEntry.jsonDecode
        |> P.required "shaperPhoenix" BossEntry.jsonDecode
        |> P.required "breachXoph" BossEntry.jsonDecode
        |> P.required "breachTul" BossEntry.jsonDecode
        |> P.required "breachEsh" BossEntry.jsonDecode
        |> P.required "breachUul" BossEntry.jsonDecode
        |> P.required "breachChayula" BossEntry.jsonDecode
        |> P.required "mastermind" BossEntry.jsonDecode


jsonDecodeUberEntry : D.Decoder UberBossEntry
jsonDecodeUberEntry =
    D.succeed UberBossEntry
        |> P.required "standard" BossEntry.jsonDecode
        |> P.required "uber" BossEntry.jsonDecode
