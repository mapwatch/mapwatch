module Model.Zone exposing (Type(..), zoneType, isTown, isMap)

import Set


hideouts : Set.Set String
hideouts =
    -- https://pathofexile.gamepedia.com/Hideout
    -- JSON.stringify($.map($('td:nth-of-type(2)', $('tbody')[0]), function(td){return td.innerText}))
    Set.fromList
        [ "Unearthed Hideout", "Enlightened Hideout", "Coastal Hideout", "Overgrown Hideout", "Lush Hideout", "Battle-scarred Hideout", "Backstreet Hideout", "Immaculate Hideout" ]


towns : Set.Set String
towns =
    Set.fromList
        -- https://pathofexile.gamepedia.com/Town
        -- JSON.stringify($.map($('li', $('ul')[0]), function(td){return td.innerText.split(' - ')[1]}))
        [ "Lioneye's Watch", "The Forest Encampment", "The Sarn Encampment", "Highgate", "Overseer's Tower", "Lioneye's Watch", "The Bridge Encampment", "The Sarn Encampment", "Highgate", "Oriath Docks", "Oriath" ]
        |> Set.union hideouts
        -- special case: this one's not really a town, but you can enter maps from it
        |> Set.union (Set.singleton "The Templar Laboratory")


type Type
    = Town
    | NotTown
    | NotZone


zoneType : Maybe String -> Type
zoneType zone =
    case zone of
        Nothing ->
            NotZone

        Just zone ->
            if Set.member zone towns then
                Town
            else
                NotTown


isTown zone =
    Set.member zone towns


isMap zone =
    Set.member zone maps


maps : Set.Set String
maps =
    Set.fromList
        -- https://pathofexile.gamepedia.com/Map
        -- JSON.stringify($.map($('td:nth-of-type(1)', $('tbody')[2]), function(td){return td.innerText.replace(/ Map$/, '')}))
        [ "Beach", "Dungeon", "Graveyard", "Lookout", "Alleyways", "Arid Lake", "Desert", "Flooded Mine", "Marshes", "Pen", "Arcade", "Burial Chambers", "Cage", "Cells", "Excavation", "Iceberg", "Leyline", "Peninsula", "Port", "Springs", "Esh's Domain", "Tul's Domain", "Xoph's Domain", "The Apex of Sacrifice", "Canyon", "Chateau", "City Square", "Courthouse", "Gorge", "Grotto", "Lighthouse", "Relic Chambers", "Strand", "Whakawairua Tuahu", "Volcano", "Ancient City", "Barrows", "Channel", "Conservatory", "Haunted Mansion", "Ivory Temple", "Maze", "Spider Lair", "Sulphur Vents", "Toxic Sewer", "The Beachhead", "Academy", "Atoll", "Maelström of Chaos", "Ashen Wood", "Cemetery", "Hallowed Ground", "Fields", "Jungle Valley", "Mausoleum", "Phantasmagoria", "Thicket", "Underground Sea", "Wharf", "Arachnid Nest", "Bazaar", "Bone Crypt", "Olmec's Sanctum", "Coral Ruins", "Dunes", "Pillars of Arun", "Gardens", "Lava Chamber", "Ramparts", "Residence", "Tribunal", "Underground River", "Caer Blaidd, Wolfpack's Den", "Armoury", "Courtyard", "The Vinktar Square", "Geode", "Infested Valley", "Laboratory", "Mineral Pools", "Mud Geyser", "Overgrown Ruin", "Shore", "Mao Kun", "The Pale Court", "Tropical Island", "Uul-Netol's Domain", "Untainted Paradise", "Vaal Pyramid", "Vaults of Atziri", "Arena", "Estuary", "Moon Temple", "The Twilight Temple", "Museum", "The Putrid Cloister", "Plateau", "Scriptorium", "Sepulchre", "Temple", "Poorjoy's Asylum", "Tower", "Vault", "Waste Pool", "Arachnid Tomb", "Belfry", "Bog", "Cursed Crypt", "The Coward's Trial", "Orchard", "Pier", "Precinct", "Shipyard", "Siege", "The Beachhead", "Wasteland", "Colonnade", "Coves", "Factory", "Mesa", "Lair", "Pit", "Primordial Pool", "Promenade", "Hall of Grandmasters", "Spider Forest", "Waterways", "Castle Ruins", "Crystal Ore", "Defiled Cathedral", "Necropolis", "Death and Taxes", "Overgrown Shrine", "Acton's Nightmare", "Racecourse", "Summit", "Torture Chamber", "Oba's Cursed Trove", "Villa", "Arsenal", "Caldera", "Core", "Chayula's Domain", "Desert Spring", "Ghetto", "Malformation", "Park", "Shrine", "Terrace", "The Alluring Abyss", "Acid Lakes", "Colosseum", "Crimson Temple", "Dark Forest", "Dig", "Palace", "Plaza", "Basilica", "Carcass", "Lava Lake", "Reef", "Sunken City", "The Beachhead", "Forge of the Phoenix", "Lair of the Hydra", "Maze of the Minotaur", "Pit of the Chimera", "Vaal Temple", "The Shaper's Realm" ]