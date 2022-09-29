module Mapwatch.BossTally exposing (BossMark, BossTally, aggregate, fromMapRun)

import Dict exposing (Dict)
import Dict.Extra
import Duration exposing (Millis)
import List.Extra
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcGroup, NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Maybe.Extra
import Set exposing (Set)


type alias BossTally =
    { atziri : UberBossSighting
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
    -- partial shaper guardian tracking: we can identify their maps, but not their completion
    -- cannot track elder guardians at all: we can't even identify their maps, much less completion
    , shaper : BossEntry
    , elder : BossEntry
    , shaperChimera : BossSighting
    , shaperHydra : BossSighting
    , shaperMinotaur : BossSighting
    , shaperPhoenix : BossSighting

    -- TODO izaro + uber izaro?
    -- TODO bestiary?
    -- TODO breachlords
    -- TODO synthesis "guardians"
    -- TODO catarina
    }


{-| A boss encounter where we know if the boss dies
-}
type alias BossEntry =
    { runs : Int
    , completed : Int
    , minDeaths : Maybe Int
    , totalDeaths : Int
    }


type alias UberBossEntry =
    { standard : BossEntry
    , uber : BossEntry
    }


{-| A boss encounter where cannot detect if the boss dies
-}
type alias BossSighting =
    { runs : Int
    , minDeaths : Maybe Int
    , totalDeaths : Int
    }


type alias UberBossSighting =
    { standard : BossSighting
    , uber : BossSighting
    }


type
    BossId
    -- TODO finish the list
    = Atziri Bool
    | UberElder Bool
    | Eater Bool
    | Exarch Bool
    | BlackStar
    | Hunger


type alias BossMark =
    { boss : BossId
    , completed : Maybe Bool
    , deaths : Int
    }


empty : BossTally
empty =
    let
        e : BossEntry
        e =
            BossEntry 0 0 Nothing 0

        ue : UberBossEntry
        ue =
            UberBossEntry e e

        s : BossSighting
        s =
            BossSighting 0 Nothing 0

        us : UberBossSighting
        us =
            UberBossSighting s s
    in
    BossTally us ue ue ue ue ue ue e e e e e e e e s s s s


aggregate : List BossMark -> BossTally
aggregate =
    List.foldl applyMark empty


fromMapRun : RawMapRun -> Maybe BossMark
fromMapRun run =
    run
        |> toMarkCompletion
        |> Maybe.map (\( id, completed ) -> BossMark id completed run.deaths)


toMarkCompletion : RawMapRun -> Maybe ( BossId, Maybe Bool )
toMarkCompletion run =
    let
        is85 : Bool
        is85 =
            Maybe.withDefault 0 run.level >= 85
    in
    case run.address.worldArea |> Maybe.map .id |> Maybe.withDefault "" of
        "MapAtziri1" ->
            Just ( Atziri False, Nothing )

        "MapAtziri2" ->
            Just ( Atziri True, Nothing )

        "MapWorldsElderArenaUber" ->
            Just ( UberElder is85, Nothing )

        "MapWorldsPrimordialBoss1" ->
            Just
                ( Hunger
                , run |> hasTextId (String.startsWith "DoomBossDefeated") NpcId.hunger |> Just
                )

        "MapWorldsPrimordialBoss2" ->
            Just
                ( BlackStar
                , run |> hasTextId (String.startsWith "TheBlackStarDeath") NpcId.blackstar |> Just
                )

        "MapWorldsPrimordialBoss3" ->
            Just
                ( Exarch is85
                , run |> hasTextId (String.startsWith "CleansingFireDefeated") NpcId.exarch |> Just
                )

        "MapWorldsPrimordialBoss4" ->
            Just
                ( Eater is85
                , run |> hasTextId (String.startsWith "ConsumeBossDefeated") NpcId.eater |> Just
                )

        _ ->
            Nothing


hasTextId : (String -> Bool) -> String -> RawMapRun -> Bool
hasTextId pred npcId run =
    run.npcSays
        -- |> Debug.todo ("hastextid: " ++ npcId ++ Debug.toString (Dict.map (\_ -> List.map (.says >> (\x -> ( x.raw, x.textId )))) run.npcSays))
        |> Dict.get npcId
        |> Maybe.map (List.filterMap (.says >> .textId) >> List.any pred)
        |> Maybe.withDefault False


applyMark : BossMark -> BossTally -> BossTally
applyMark mark tally =
    case mark.boss of
        Atziri isUber ->
            { tally | atziri = tally.atziri |> applyUberSighting isUber mark }

        UberElder isUber ->
            { tally | uberelder = tally.uberelder |> applyUberEntry isUber mark }

        Exarch isUber ->
            { tally | exarch = tally.exarch |> applyUberEntry isUber mark }

        Eater isUber ->
            { tally | eater = tally.eater |> applyUberEntry isUber mark }

        BlackStar ->
            { tally | blackstar = tally.blackstar |> applyEntry mark }

        Hunger ->
            { tally | hunger = tally.hunger |> applyEntry mark }


applyUberEntry : Bool -> BossMark -> UberBossEntry -> UberBossEntry
applyUberEntry isUber mark entry =
    if isUber then
        { entry | uber = applyEntry mark entry.uber }

    else
        { entry | standard = applyEntry mark entry.standard }


applyEntry : BossMark -> BossEntry -> BossEntry
applyEntry mark entry =
    { runs = entry.runs + 1
    , completed =
        entry.completed
            + (case mark.completed of
                Just True ->
                    1

                Just False ->
                    0

                Nothing ->
                    -- uh oh: BossEntry requires completion data, but this mark didn't provide it.
                    -- TODO integrate this with bossid?
                    Debug.todo "BossEntry without completion data"
              )
    , totalDeaths = entry.totalDeaths + mark.deaths
    , minDeaths = entry.minDeaths |> Maybe.withDefault mark.deaths |> min mark.deaths |> Just
    }


applyUberSighting : Bool -> BossMark -> UberBossSighting -> UberBossSighting
applyUberSighting isUber mark entry =
    if isUber then
        { entry | uber = applySighting mark entry.uber }

    else
        { entry | standard = applySighting mark entry.standard }


applySighting : BossMark -> BossSighting -> BossSighting
applySighting mark entry =
    { runs = entry.runs + 1
    , totalDeaths = entry.totalDeaths + mark.deaths
    , minDeaths = entry.minDeaths |> Maybe.withDefault mark.deaths |> min mark.deaths |> Just
    }
