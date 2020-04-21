module Mapwatch.MapRun.Conqueror exposing
    ( Encounter(..)
    , Id(..)
    , State
    , State1
    , createState
    , emptyState
    , encounter
    , idFromNpc
    , ids
    , npcFromId
    , searchString
    , toString
    )

import Dict exposing (Dict)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Maybe.Extra
import Set exposing (Set)


type Id
    = Baran
    | Veritania
    | AlHezmin
    | Drox


type Encounter
    = Taunt Int
    | Fight


type alias State =
    { baran : State1
    , veritania : State1
    , alHezmin : State1
    , drox : State1
    }


type alias State1 =
    { encounter : Maybe Encounter
    , region : Maybe Region
    , sightings : Set Region
    }


type alias Region =
    String


ids =
    [ Baran, Veritania, AlHezmin, Drox ]


emptyState : State
emptyState =
    State emptyState1 emptyState1 emptyState1 emptyState1


emptyState1 : State1
emptyState1 =
    State1 Nothing Nothing Set.empty


encounter : Id -> List String -> Maybe Encounter
encounter cid textIds =
    -- see https://github.com/mapwatch/mapwatch/issues/57, https://github.com/mapwatch/mapwatch/issues/69
    -- veritania's 4-stone taunt order does not match her dialogue ids, like other taunts. special-case them.
    if List.any (String.startsWith "VeritaniaFourStoneEncounter2") textIds then
        Just (Taunt 3)

    else if List.any (String.startsWith "VeritaniaFourStoneEncounter3") textIds then
        Just (Taunt 2)

    else
    -- all other taunts (including veritania [0-3]-stones)
    if
        List.any (String.contains "StoneEncounter1") textIds || List.any (String.contains "StoneEncounterOne") textIds
    then
        Just (Taunt 1)

    else if List.any (String.contains "StoneEncounter2") textIds || List.any (String.contains "StoneEncounterTwo") textIds then
        Just (Taunt 2)

    else if List.any (String.contains "StoneEncounter3") textIds || List.any (String.contains "StoneEncounterThree") textIds then
        Just (Taunt 3)
        -- else if List.any (String.contains "Death") textIds || List.any (String.contains "Flee") textIds then
        -- Just (ConquerorKilled)

    else if List.any (String.contains "Fight") textIds then
        Just Fight

    else
        Nothing


npcFromId : Id -> NpcId
npcFromId c =
    case c of
        Baran ->
            NpcId.baran

        Veritania ->
            NpcId.veritania

        AlHezmin ->
            NpcId.alHezmin

        Drox ->
            NpcId.drox


idByNpc : Dict NpcId Id
idByNpc =
    ids |> List.map (\c -> ( npcFromId c, c )) |> Dict.fromList


idFromNpc : NpcId -> Maybe Id
idFromNpc npcId =
    Dict.get npcId idByNpc


toString : Id -> String
toString id =
    case id of
        Baran ->
            "baran"

        Veritania ->
            "veritania"

        AlHezmin ->
            "alHezmin"

        Drox ->
            "drox"


type alias Runlike a =
    { a
        | address : Address
        , conqueror : Maybe ( Id, Encounter )
    }


createState : List (Runlike a) -> State
createState runs0 =
    let
        loop : List (Runlike a) -> Bool -> State -> State
        loop runs encountersLocked state =
            case runs of
                [] ->
                    state

                run :: tail ->
                    case run.address.worldArea |> Maybe.map .id of
                        -- eye of the storm; sirus arena
                        -- earlier maps don't matter, sirus resets the state - we're done
                        Just "AtlasExilesBoss5" ->
                            loop tail True state

                        _ ->
                            loop tail encountersLocked <|
                                case run.conqueror of
                                    Nothing ->
                                        state

                                    Just ( id, encounter_ ) ->
                                        case id of
                                            Baran ->
                                                { state | baran = state.baran |> applyEncounter run encountersLocked encounter_ }

                                            Veritania ->
                                                { state | veritania = state.veritania |> applyEncounter run encountersLocked encounter_ }

                                            AlHezmin ->
                                                { state | alHezmin = state.alHezmin |> applyEncounter run encountersLocked encounter_ }

                                            Drox ->
                                                { state | drox = state.drox |> applyEncounter run encountersLocked encounter_ }
    in
    loop runs0 False emptyState


applyEncounter : Runlike a -> Bool -> Encounter -> State1 -> State1
applyEncounter mapRun encountersLocked encounter_ state0 =
    let
        region : Maybe String
        region =
            mapRun.address.worldArea |> Maybe.andThen .atlasRegion

        state =
            case region of
                Nothing ->
                    state0

                Just r ->
                    { state0 | sightings = state0.sightings |> Set.insert r }
    in
    if encountersLocked then
        state

    else
        { state
            | encounter = state.encounter |> Maybe.Extra.orElse (Just encounter_)
            , region = state.region |> Maybe.Extra.orElse region
        }


searchString : ( Id, Encounter ) -> String
searchString ( id, enc ) =
    "conqueror:"
        ++ (case enc of
                Taunt n ->
                    "taunt" ++ String.fromInt n

                Fight ->
                    "fight"
           )
        ++ ":"
        ++ toString id
