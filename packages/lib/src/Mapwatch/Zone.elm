module Mapwatch.Zone exposing (Master(..), SideZoneType(..), Type(..), guardianToString, isMap, isTown, maps, masterToString, sideZoneType, zoneType)

import Dict
import Mapwatch.MapList exposing (mapList, zoneAliases)
import Maybe.Extra
import Set


type Type
    = Town
    | NotTown
    | NotZone


zoneType : Maybe String -> Type
zoneType mzone =
    case mzone of
        Nothing ->
            NotZone

        Just zone ->
            if Set.member zone towns then
                Town

            else
                NotTown


type
    Master
    -- catarina/vorici/elreon don't have side areas in maps
    = Zana
    | Tora
    | Haku
    | Vagan


masterToString : Master -> String
masterToString =
    Debug.toString


type SideZoneType
    = OtherSideZone
    | Mission Master
    | ElderGuardian Guardian


sideZoneType : Maybe String -> SideZoneType
sideZoneType mzone =
    case mzone of
        Nothing ->
            OtherSideZone

        Just zone ->
            -- given that this is a side zone, what kind is it?
            case Dict.get zone sideZoneDict of
                Nothing ->
                    OtherSideZone

                Just t ->
                    t


isTown zone =
    Set.member zone towns


isMap zone =
    Set.member zone maps


type Guardian
    = Eradicator
    | Constrictor
    | Purifier
    | Enslaver


guardianToString : Guardian -> String
guardianToString =
    Debug.toString


valkeys : val -> List String -> Dict.Dict String val
valkeys val keys =
    List.map (\z -> ( z, val )) keys
        |> Dict.fromList


sideZoneDict : Dict.Dict String SideZoneType
sideZoneDict =
    List.foldl Dict.union
        Dict.empty
        [ Dict.map (\_ -> ElderGuardian) elderGuardianZones
        , valkeys (Mission Tora) (Set.toList toraMissions)
        , valkeys (Mission Haku) (Set.toList hakuMissions)
        , valkeys (Mission Vagan) (Set.toList vaganMissions)
        , valkeys (Mission Zana) (Set.toList maps)
        ]


elderGuardianZones : Dict.Dict String Guardian
elderGuardianZones =
    List.foldl Dict.union
        Dict.empty
        -- https://pathofexile.gamepedia.com/The_Eradicator
        [ valkeys Eradicator [ "Repository of Derision", "Spires of Delusion", "Manor of Madness" ]

        -- https://pathofexile.gamepedia.com/The_Constrictor
        , valkeys Constrictor [ "Ruins of Despair", "Island of Devastation", "Sea of Isolation" ]

        -- https://pathofexile.gamepedia.com/The_Purifier
        , valkeys Purifier [ "Vaults of Insanity", "Halls of Delirium", "Pits of Sorrow" ]

        -- https://pathofexile.gamepedia.com/The_Enslaver
        , valkeys Enslaver [ "River of Hysteria", "Desert of Dementia", "Wastes of Lunacy" ]
        ]


hakuMissions : Set.Set String
hakuMissions =
    -- https://pathofexile.gamepedia.com/Mission_areas
    -- JSON.stringify($('td:nth-of-type(4)', $('tbody')[0]).map(function(){return this.innerText}).filter(function(){return !!this.valueOf()}).toArray())
    Set.fromList <|
        [ "Haunted Cave", "Haunted Ruin", "Haunted Crypt", "Haunted Shrine", "Haunted Cell", "Haunted Mansion", "Haunted Trench", "Haunted Lair", "Haunted Abyss", "Haunted Descent", "Haunted Depth", "Haunted Tomb", "Haunted Shed" ]
            -- TODO not sure why these are missing from the wiki... bet there's more
            ++ [ "Haunted Pit" ]


toraMissions : Set.Set String
toraMissions =
    -- https://pathofexile.gamepedia.com/Mission_areas
    -- JSON.stringify($('td:nth-of-type(5)', $('tbody')[0]).map(function(){return this.innerText}).filter(function(){return !!this.valueOf()}).toArray())
    Set.fromList <|
        [ "Reeking Den", "Rotting Den", "Defiled Den, Desecrated Lair", "Musty Lair", "Suffocating Lair", "Putrid Lair", "Ruined Lair", "Rancid Lair", "Infested Lair", "Dank Den", "Musky Lair" ]
            -- TODO not sure why these are missing from the wiki... bet there's more
            ++ [ "Sooty Lair" ]


vaganMissions : Set.Set String
vaganMissions =
    -- https://pathofexile.gamepedia.com/Mission_areas
    -- JSON.stringify($('td:nth-of-type(6)', $('tbody')[0]).map(function(){return this.innerText}).filter(function(){return !!this.valueOf()}).toArray())
    Set.fromList
        [ "Rugged Pit", "Ruined Arena", "Austere Arena, Hallowed Arena", "Scholar's Arena", "Blood Pit", "Burnt Cage", "Court Arena", "Sewage Pit", "Webbed Arena", "Watery Pit", "Ageless Arena", "Ramshackle Arena" ]


hideouts : Set.Set String
hideouts =
    -- from the in-game hideout selection screen
    Set.fromList
        [ "Backstreet Hideout"
        , "Baleful Hideout"
        , "Battle-scarred Hideout"
        , "Cartographer's Hideout"
        , "Coastal Hideout"
        , "Coral Hideout"
        , "Desert Hideout"
        , "Enlightened Hideout"
        , "Excavated Hideout"
        , "Immaculate Hideout"
        , "Lush Hideout"
        , "Luxurious Hideout"
        , "Skeletal Hideout"
        , "Stately Hideout"
        , "Undercity Hideout"
        , "Unearthed Hideout"
        ]


englishTowns : Set.Set String
englishTowns =
    Set.fromList
        -- https://pathofexile.gamepedia.com/Town
        -- JSON.stringify($.map($('li', $('ul')[0]), function(td){return td.innerText.split(' - ')[1]}))
        [ "Lioneye's Watch", "The Forest Encampment", "The Sarn Encampment", "Highgate", "Overseer's Tower", "Lioneye's Watch", "The Bridge Encampment", "The Sarn Encampment", "Highgate", "Oriath Docks", "Oriath" ]
        |> Set.union hideouts
        -- special case: this one's not really a town, but you can enter maps from it
        |> Set.union (Set.singleton "The Templar Laboratory")
        -- special case: bestiary league zones shouldn't interrupt a map run, so count them as towns, even though they allow fighting
        -- https://pathofexile.gamepedia.com/The_Menagerie
        |> Set.union (Set.fromList [ "The Menagerie", "Menagerie Caverns", "Menagerie Depths", "Menagerie Sands", "Menagerie Wilds" ])


towns : Set.Set String
towns =
    zoneAliases
        |> List.map
            (\( nonenglish, english ) ->
                if Set.member english englishTowns then
                    Just nonenglish

                else
                    Nothing
            )
        |> Maybe.Extra.values
        |> Set.fromList
        |> Set.union englishTowns


maps : Set.Set String
maps =
    Set.fromList <|
        List.map .name mapList
            -- It's awkward to not track Zana dailies. This is the quickest fix.
            ++ [ "Crumbled Laboratory" ]
            -- I'm curious about incursion temple times too
            ++ [ "The Temple of Atzoatl" ]
