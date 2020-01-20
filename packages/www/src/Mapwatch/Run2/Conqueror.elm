module Mapwatch.Run2.Conqueror exposing
    ( Encounter(..)
    , Id(..)
    , State
    , createState
    , encounter
    , idFromNpc
    , ids
    , npcFromId
    )

import Dict exposing (Dict)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Maybe.Extra


type Id
    = Baran
    | Veritania
    | AlHezmin
    | Drox


type Encounter
    = Taunt Int
    | Fight


type alias State =
    { baran : Maybe Encounter
    , veritania : Maybe Encounter
    , alHezmin : Maybe Encounter
    , drox : Maybe Encounter
    }


ids =
    [ Baran, Veritania, AlHezmin, Drox ]


encounter : Id -> List String -> Maybe Encounter
encounter cid textIds =
    if List.any (String.contains "StoneEncounter1") textIds || List.any (String.contains "StoneEncounterOne") textIds then
        Just (Taunt 1)

    else if List.any (String.contains "StoneEncounter2") textIds || List.any (String.contains "StoneEncounterTwo") textIds then
        -- see https://github.com/mapwatch/mapwatch/issues/57 - poe is using this order, and we have to match it
        if cid == Veritania then
            Just (Taunt 3)

        else
            Just (Taunt 2)

    else if List.any (String.contains "StoneEncounter3") textIds || List.any (String.contains "StoneEncounterThree") textIds then
        -- see https://github.com/mapwatch/mapwatch/issues/57 - poe is using this order, and we have to match it
        if cid == Veritania then
            Just (Taunt 2)

        else
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
        loop : List (Runlike a) -> State -> State
        loop runs state =
            case runs of
                [] ->
                    state

                run :: tail ->
                    case run.address.worldArea |> Maybe.map .id of
                        -- eye of the storm; sirus arena
                        -- earlier maps don't matter, sirus resets the state - we're done
                        Just "AtlasExilesBoss5" ->
                            state

                        _ ->
                            loop tail <|
                                case run.conqueror of
                                    Nothing ->
                                        state

                                    Just ( id, encounter_ ) ->
                                        case id of
                                            Baran ->
                                                { state | baran = state.baran |> Maybe.Extra.or (Just encounter_) }

                                            Veritania ->
                                                { state | veritania = state.veritania |> Maybe.Extra.or (Just encounter_) }

                                            AlHezmin ->
                                                { state | alHezmin = state.alHezmin |> Maybe.Extra.or (Just encounter_) }

                                            Drox ->
                                                { state | drox = state.drox |> Maybe.Extra.or (Just encounter_) }
    in
    loop runs0
        { baran = Nothing
        , veritania = Nothing
        , alHezmin = Nothing
        , drox = Nothing
        }
