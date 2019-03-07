module Mapwatch.MapList exposing (Map, mapList, url, zoneAliases, zoneAliasesDict)

import Dict as Dict exposing (Dict)
import Maybe.Extra
import Regex as Regex exposing (Regex)


type alias Map =
    { name : String, tier : Int, unique : Bool }


zoneAliasesDict =
    Dict.fromList zoneAliases


englishMapsByName : Dict String Map
englishMapsByName =
    englishMapList
        |> List.map (\m -> ( m.name, m ))
        |> Dict.fromList


mapList : List Map
mapList =
    let
        buildAlias nonenglish english =
            Dict.get english englishMapsByName |> Maybe.map (\m -> { m | name = nonenglish })
    in
    englishMapList ++ (List.map (\( a, b ) -> buildAlias a b) zoneAliases |> Maybe.Extra.values)


mapsByName : Dict String Map
mapsByName =
    mapList
        |> List.map (\m -> ( m.name, m ))
        |> Dict.fromList


englishUrlNames =
    Dict.union specialUrlNames rawUrlNames


urlNames =
    zoneAliases
        |> List.map
            (\( nonenglish, english ) ->
                Dict.get english englishUrlNames
                    |> Maybe.map (\b -> ( nonenglish, b ))
            )
        |> Maybe.Extra.values
        |> Dict.fromList
        |> Dict.union englishUrlNames


url : String -> Maybe String
url name =
    let
        fixUrl : Map -> String -> String
        fixUrl map path =
            let
                -- build the query string - one parameter at a time, so I can document them
                qs =
                    -- how large is the map icon?
                    [ "scale=1"

                    -- what atlas version are we using? 0: atlas of worlds; 1: war for the atlas, 2: betrayal league
                    -- best docs I've got for that: https://www.pathofexile.com/forum/view-thread/2254801/page/1#p15971585
                    , "mn=2"

                    -- don't draw the "shaped" circle on the map. mr=1 draws it.
                    , "mr=0"

                    -- map tier sets the white/yellow/red color
                    , "mt=" ++ String.fromInt map.tier
                    ]
            in
            path ++ "?" ++ String.join "&" qs

        -- old approach to icon urls. Keep it here until I'm confident in the new approach (because git history digging is tedious).
        -- Safe to delete if we haven't seen broken map images for a while.
        --Regex.replace
        --    (Regex.fromString "New/([a-zA-Z]+)\\d?\\.png" |> Maybe.withDefault Regex.never)
        --    (\match ->
        --        case List.head <| List.take 1 match.submatches of
        --            Nothing ->
        --                Debug.todo ("url parse failed. " ++ map.name)
        --
        --            Just Nothing ->
        --                Debug.todo ("url parse failed (2). " ++ map.name)
        --
        --            Just (Just urlname) ->
        --                let
        --                    colorTier =
        --                        -- 1 = white, 2 = yellow, 3 = red. Used in map urls.
        --                        clamp 1 3 <| ceiling <| toFloat map.tier / 5
        --                in
        --                urlname ++ String.fromInt colorTier ++ ".png?scale=1"
        --    )
    in
    Maybe.map2 fixUrl
        (Dict.get name mapsByName)
        (Dict.get name urlNames)
        |> Maybe.map ((++) "https:")


specialUrlNames =
    -- thanks, https://poecraft.com/atlas and #/debug/mapicons
    -- and https://poecraft.com/js/app/generated/atlasmaps.js?v=5dc7fdae
    Dict.fromList
        -- these maps are in a separate poedb.tw section for some reason, filled in manually. http://poedb.tw/us/unique.php?cn=Map
        [ ( "Hallowed Ground", "//web.poecdn.com/image/Art/2DItems/Maps/HallowedGround.png" )
        , ( "The Coward's Trial", "//web.poecdn.com/image/Art/2DItems/Maps/UndeadSiege.png" )
        , ( "Mao Kun", "//web.poecdn.com/image/Art/2DItems/Maps/FairgravesMap01.png" )
        , ( "Untainted Paradise", "//web.poecdn.com/image/Art/2DItems/Maps/UniqueMap2.png" )
        , ( "Olmec's Sanctum", "//web.poecdn.com/image/Art/2DItems/Maps/olmec.png" )

        -- TODO: oops, 3 maps are named "the beachhead" with different icons: white, yellow, red.
        -- Not worth changing how everything works just for this.
        , ( "The Beachhead", "//web.poecdn.com/image/Art/2DItems/Maps/HarbingerRed.png" )

        -- These aren't really maps, but let's show them with icons anyway
        , ( "The Temple of Atzoatl", "//web.poecdn.com/image/Art/2DItems/Effects/Portals/IncursionPortal.png" )
        , ( "Crumbled Laboratory", "//web.poecdn.com/image/Art/2DItems/Hideout/Interactive/CartographyDevice.png" )
        , ( "The Apex of Sacrifice", "//web.poecdn.com/image/Art/2DItems/Maps/VaalComplete.png" )
        , ( "The Alluring Abyss", "//web.poecdn.com/image/Art/2DItems/Maps/UberVaalComplete.png" )
        , ( "The Pale Court", "//web.poecdn.com/image/Art/2DItems/Maps/PaleCourtComplete.png" )
        , ( "The Shaper's Realm", "//web.poecdn.com/image/Art/2DItems/Maps/ShaperComplete.png" )
        ]


specialMapList =
    [ { name = "The Temple of Atzoatl", tier = 0, unique = False }
    , { name = "Crumbled Laboratory", tier = 0, unique = False }
    , { name = "The Apex of Sacrifice", tier = 0, unique = True }
    , { name = "The Alluring Abyss", tier = 0, unique = True }
    , { name = "The Pale Court", tier = 0, unique = True }
    , { name = "The Shaper's Realm", tier = 17, unique = True }
    ]


englishMapList =
    specialMapList ++ extractedMapList


{-| maps grouped by tier
-}
extractedMapList =
    -- Built from reading https://www.reddit.com/r/pathofexile/comments/ax29hh/complete_synthesis_atlas_tiered_labeled_colored/
    [ { tier = 1, unique = False, name = "Cursed Crypt" }
    , { tier = 1, unique = False, name = "Fungal Hollow" }
    , { tier = 1, unique = False, name = "Iceberg" }
    , { tier = 1, unique = False, name = "Alleyways" }
    , { tier = 2, unique = False, name = "Dungeon" }
    , { tier = 2, unique = False, name = "Excavation" }
    , { tier = 2, unique = False, name = "Haunted Mansion" }
    , { tier = 2, unique = False, name = "Strand" }
    , { tier = 2, unique = False, name = "Peninsula" }
    , { tier = 2, unique = False, name = "Ramparts" }
    , { tier = 3, unique = False, name = "Arid Lake" }
    , { tier = 3, unique = False, name = "Leyline" }
    , { tier = 3, unique = False, name = "Barrows" }
    , { tier = 3, unique = False, name = "Channel" }
    , { tier = 3, unique = False, name = "Spider Lair" }
    , { tier = 3, unique = False, name = "Jungle Valley" }
    , { tier = 3, unique = False, name = "Atoll" }
    , { tier = 3, unique = False, name = "Ashen Wood" }
    , { tier = 3, unique = False, name = "Desert" }
    , { tier = 3, unique = False, name = "Maze" }
    , { tier = 4, unique = False, name = "Beach" }
    , { tier = 4, unique = False, name = "Port" }
    , { tier = 4, unique = False, name = "Arcade" }
    , { tier = 4, unique = False, name = "Mausoleum" }
    , { tier = 4, unique = False, name = "Flooded Mine" }
    , { tier = 4, unique = False, name = "City Square" }
    , { tier = 4, unique = False, name = "Glacier" }
    , { tier = 4, unique = False, name = "Armoury" }
    , { tier = 4, unique = False, name = "Underground Sea" }
    , { tier = 4, unique = False, name = "Lookout" }
    , { tier = 5, unique = False, name = "Pen" }
    , { tier = 5, unique = False, name = "Ancient City" }
    , { tier = 5, unique = False, name = "Graveyard" }
    , { tier = 5, unique = False, name = "Marshes" }
    , { tier = 5, unique = False, name = "Thicket" }
    , { tier = 5, unique = False, name = "Courtyard" }
    , { tier = 5, unique = False, name = "Crater" }
    , { tier = 5, unique = False, name = "Cage" }
    , { tier = 5, unique = False, name = "Grotto" }
    , { tier = 5, unique = False, name = "Sulphur Vents" }
    , { tier = 6, unique = False, name = "Sepulchre" }
    , { tier = 6, unique = False, name = "Lair" }
    , { tier = 6, unique = False, name = "Vault" }
    , { tier = 6, unique = False, name = "Burial Chambers" }
    , { tier = 6, unique = False, name = "Necropolis" }
    , { tier = 6, unique = False, name = "Overgrown Shrine" }
    , { tier = 6, unique = False, name = "Primordial Pool" }
    , { tier = 6, unique = False, name = "Pit" }
    , { tier = 6, unique = False, name = "Promenade" }
    , { tier = 6, unique = False, name = "Residence" }
    , { tier = 6, unique = False, name = "Geode" }
    , { tier = 7, unique = False, name = "Fields" }
    , { tier = 7, unique = False, name = "Ghetto" }
    , { tier = 7, unique = False, name = "Bone Crypt" }
    , { tier = 7, unique = False, name = "Mineral Pools" }
    , { tier = 7, unique = False, name = "Mud Geyser" }
    , { tier = 7, unique = False, name = "Bazaar" }
    , { tier = 7, unique = False, name = "Estuary" }
    , { tier = 7, unique = False, name = "Spider Forest" }
    , { tier = 7, unique = False, name = "Academy" }
    , { tier = 7, unique = False, name = "Shore" }
    , { tier = 7, unique = False, name = "Pier" }
    , { tier = 8, unique = False, name = "Dunes" }
    , { tier = 8, unique = False, name = "Lighthouse" }
    , { tier = 8, unique = False, name = "Orchard" }
    , { tier = 8, unique = False, name = "Conservatory" }
    , { tier = 8, unique = False, name = "Phantasmagoria" }
    , { tier = 8, unique = False, name = "Volcano" }
    , { tier = 8, unique = False, name = "Cemetery" }
    , { tier = 8, unique = False, name = "Lava Chamber" }
    , { tier = 8, unique = False, name = "Waterways" }
    , { tier = 8, unique = False, name = "Toxic Sewer" }
    , { tier = 8, unique = False, name = "Arachnid Tomb" }
    , { tier = 9, unique = False, name = "Underground River" }
    , { tier = 9, unique = False, name = "Laboratory" }
    , { tier = 9, unique = False, name = "Canyon" }
    , { tier = 9, unique = False, name = "Vaal Pyramid" }
    , { tier = 9, unique = False, name = "Tropical Island" }
    , { tier = 9, unique = False, name = "Coral Ruins" }
    , { tier = 9, unique = False, name = "Museum" }
    , { tier = 9, unique = False, name = "Castle Ruins" }
    , { tier = 9, unique = False, name = "Temple" }
    , { tier = 9, unique = False, name = "Villa" }
    , { tier = 9, unique = False, name = "Cells" }
    , { tier = 10, unique = False, name = "Overgrown Ruin" }
    , { tier = 10, unique = False, name = "Plateau" }
    , { tier = 10, unique = False, name = "Moon Temple" }
    , { tier = 10, unique = False, name = "Mesa" }
    , { tier = 10, unique = False, name = "Scriptorium" }
    , { tier = 10, unique = False, name = "Factory" }
    , { tier = 10, unique = False, name = "Relic Chambers" }
    , { tier = 10, unique = False, name = "Arachnid Nest" }
    , { tier = 10, unique = False, name = "Chateau" }
    , { tier = 10, unique = False, name = "Wharf" }
    , { tier = 11, unique = False, name = "Desert Spring" }
    , { tier = 11, unique = False, name = "Palace" }
    , { tier = 11, unique = False, name = "Wasteland" }
    , { tier = 11, unique = False, name = "Arsenal" }
    , { tier = 11, unique = False, name = "Coves" }
    , { tier = 11, unique = False, name = "Dig" }
    , { tier = 11, unique = False, name = "Arena" }
    , { tier = 11, unique = False, name = "Bog" }
    , { tier = 11, unique = False, name = "Basilica" }
    , { tier = 11, unique = False, name = "Infested Valley" }
    , { tier = 12, unique = False, name = "Crystal Ore" }
    , { tier = 12, unique = False, name = "Malformation" }
    , { tier = 12, unique = False, name = "Reef" }
    , { tier = 12, unique = False, name = "Courthouse" }
    , { tier = 12, unique = False, name = "Terrace" }
    , { tier = 12, unique = False, name = "Acid Caverns" }
    , { tier = 12, unique = False, name = "Sunken City" }
    , { tier = 12, unique = False, name = "Carcass" }
    , { tier = 12, unique = False, name = "Precinct" }
    , { tier = 13, unique = False, name = "Gardens" }
    , { tier = 13, unique = False, name = "Siege" }
    , { tier = 13, unique = False, name = "Tower" }
    , { tier = 13, unique = False, name = "Colonnade" }
    , { tier = 13, unique = False, name = "Summit" }
    , { tier = 13, unique = False, name = "Crimson Temple" }
    , { tier = 13, unique = False, name = "Park" }
    , { tier = 13, unique = False, name = "Colosseum" }
    , { tier = 13, unique = False, name = "Shipyard" }
    , { tier = 14, unique = False, name = "Primordial Blocks" }
    , { tier = 14, unique = False, name = "Racecourse" }
    , { tier = 14, unique = False, name = "Plaza" }
    , { tier = 14, unique = False, name = "Shrine" }
    , { tier = 14, unique = False, name = "Belfry" }
    , { tier = 14, unique = False, name = "Ivory Temple" }
    , { tier = 14, unique = False, name = "Caldera" }
    , { tier = 15, unique = False, name = "Defiled Cathedral" }
    , { tier = 15, unique = False, name = "Lava Lake" }
    , { tier = 15, unique = False, name = "Dark Forest" }
    , { tier = 15, unique = False, name = "Core" }
    , { tier = 15, unique = False, name = "Waste Pool" }
    , { tier = 16, unique = False, name = "Pit of the Chimera" }
    , { tier = 16, unique = False, name = "Lair of the Hydra" }
    , { tier = 16, unique = False, name = "Maze of the Minotaur" }
    , { tier = 16, unique = False, name = "Forge of the Phoenix" }
    , { tier = 16, unique = False, name = "Vaal Temple" }
    ]
        ++ uniqueMapList


uniqueMapList =
    [ { name = "Whakawairua Tuahu", tier = 4, unique = True }
    , { name = "The Beachhead", tier = 5, unique = True }
    , { name = "Maelström of Chaos", tier = 1, unique = True }
    , { name = "Hallowed Ground", tier = 6, unique = True }
    , { name = "Olmec's Sanctum", tier = 3, unique = True }
    , { name = "Pillars of Arun", tier = 7, unique = True }
    , { name = "Caer Blaidd, Wolfpack's Den", tier = 7, unique = True }
    , { name = "The Vinktar Square", tier = 4, unique = True }
    , { name = "Mao Kun", tier = 8, unique = True }
    , { name = "Untainted Paradise", tier = 9, unique = True }
    , { name = "Vaults of Atziri", tier = 5, unique = True }
    , { name = "The Twilight Temple", tier = 9, unique = True }
    , { name = "The Putrid Cloister", tier = 9, unique = True }
    , { name = "Poorjoy's Asylum", tier = 9, unique = True }
    , { name = "The Coward's Trial", tier = 3, unique = True }
    , { name = "The Beachhead", tier = 10, unique = True }
    , { name = "Hall of Grandmasters", tier = 11, unique = True }
    , { name = "Death and Taxes", tier = 12, unique = True }
    , { name = "Acton's Nightmare", tier = 12, unique = True }
    , { name = "Oba's Cursed Trove", tier = 5, unique = True }
    , { name = "The Beachhead", tier = 15, unique = True }
    ]


rawUrlNames =
    Dict.fromList
        -- TODO: I really need to learn how to mine ggpk myself...
        -- http://poedb.tw/us/area.php?cn=Map
        {-

           '['+$('tr',$('table')[0]).slice(1).map(function(){return {
             name:$('td', this)[1].innerText.trim().replace(/ Map$/, ''),
             img:(($('img', this)[0]||{}).src||'').split('.png')[0].split('/').reverse()[0],
             imgs: $('img', this).toArray().length
           }})
           .filter(function(){return this.name && this.img && this.imgs === 1})
           .map(function(){return "(\""+this.name+"\",\""+this.img+"\")"})
           .toArray().join("\n,")+']'

        -}
        [ ( "Lookout", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Lookout.png" )
        , ( "Beach", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Beach.png" )
        , ( "Graveyard", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Graveyard.png" )
        , ( "Dungeon", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Dungeon.png" )
        , ( "Alleyways", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Alleyways.png" )
        , ( "Pen", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Pen.png" )
        , ( "Desert", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Desert.png" )
        , ( "Arid Lake", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/AridLake.png" )
        , ( "Flooded Mine", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Cavern.png" )
        , ( "Marshes", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Marshes.png" )
        , ( "Iceberg", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Iceberg.png" )
        , ( "Cage", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Cage.png" )
        , ( "Fungal Hollow", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/FungalCaverns.png" )
        , ( "Excavation", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Excavation.png" )
        , ( "Leyline", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/SulphurWastes.png" )
        , ( "Peninsula", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/DryPeninsula.png" )
        , ( "Port", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Quay.png" )
        , ( "Burial Chambers", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/BurialChambers.png" )
        , ( "Cells", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Cells.png" )
        , ( "Arcade", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Arcade.png" )
        , ( "City Square", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/CitySquare.png" )
        , ( "Relic Chambers", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Antiquary.png" )
        , ( "Courthouse", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Courthouse.png" )
        , ( "Strand", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Strand.png" )
        , ( "Whakawairua Tuahu", "//web.poecdn.com/image/Art/2DItems/Maps/UniqueMapEye.png" )
        , ( "Chateau", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Chateau.png" )
        , ( "Grotto", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Grotto.png" )
        , ( "Glacier", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Glacier.png" )
        , ( "Volcano", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Volcano.png" )
        , ( "Lighthouse", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Beacon.png" )
        , ( "Canyon", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Canyon.png" )
        , ( "Conservatory", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Baths.png" )
        , ( "Sulphur Vents", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Corrosion.png" )
        , ( "Haunted Mansion", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Chambers.png" )
        , ( "Maze", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Maze.png" )
        , ( "Channel", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Channel.png" )
        , ( "Toxic Sewer", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Sewer.png" )
        , ( "Ancient City", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/VaalCity.png" )
        , ( "Ivory Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/IvoryTemple.png" )
        , ( "Spider Lair", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/SpiderLair.png" )
        , ( "Barrows", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Barrows.png" )
        , ( "Mausoleum", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Mausoleum.png" )
        , ( "Fields", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Fields.png" )
        , ( "Jungle Valley", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/JungleValley.png" )
        , ( "Phantasmagoria", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Phantasmagoria.png" )
        , ( "Academy", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Academy.png" )
        , ( "Thicket", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Thicket.png" )
        , ( "Wharf", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Wharf.png" )
        , ( "Ashen Wood", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/DryWoods.png" )
        , ( "Atoll", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Atoll.png" )
        , ( "Maelström of Chaos", "//web.poecdn.com/image/Art/2DItems/Maps/MaelstromofChaos.png" )
        , ( "Cemetery", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Cemetery.png" )
        , ( "Underground Sea", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/UndergroundSea.png" )
        , ( "Crater", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Tribunal.png" )
        , ( "Coral Ruins", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/CorpseTrench.png" )
        , ( "Lava Chamber", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Crematorium.png" )
        , ( "Residence", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Residence.png" )
        , ( "Ramparts", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Ramparts.png" )
        , ( "Dunes", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Dunes.png" )
        , ( "Pillars of Arun", "//web.poecdn.com/image/Art/2DItems/Maps/PillarsOfVastiri.png" )
        , ( "Bone Crypt", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Catacomb.png" )
        , ( "Underground River", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/UndergroundRiver.png" )
        , ( "Caer Blaidd, Wolfpack's Den", "//web.poecdn.com/image/Art/2DItems/Maps/WolfMap.png" )
        , ( "Gardens", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Terrace.png" )
        , ( "Arachnid Nest", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/ArachnidNest.png" )
        , ( "Bazaar", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Bazaar.png" )
        , ( "Laboratory", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Laboratory.png" )
        , ( "Infested Valley", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Infestation.png" )
        , ( "Overgrown Ruin", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/OvergrownRuin.png" )
        , ( "Vaal Pyramid", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/VaalPyramid.png" )
        , ( "Vaults of Atziri", "//web.poecdn.com/image/Art/2DItems/Maps/UniqueMap1.png" )
        , ( "Geode", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Quarry.png" )
        , ( "Armoury", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Armory.png" )
        , ( "Courtyard", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Courtyard.png" )
        , ( "The Vinktar Square", "//web.poecdn.com/image/Art/2DItems/Maps/TheVinktarSquare.png" )
        , ( "Mud Geyser", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/MudGeyser.png" )
        , ( "Shore", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Shore.png" )
        , ( "Tropical Island", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/TropicalIsland.png" )
        , ( "Mineral Pools", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/MineralPools.png" )
        , ( "Moon Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/LunarisTemple.png" )
        , ( "The Twilight Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Celestial.png" )
        , ( "Sepulchre", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Sepulchre.png" )
        , ( "Tower", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Tower.png" )
        , ( "Waste Pool", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/WastePool.png" )
        , ( "Plateau", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Plateau.png" )
        , ( "Estuary", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Estuary.png" )
        , ( "Vault", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Vault.png" )
        , ( "Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Temple.png" )
        , ( "Poorjoy's Asylum", "//web.poecdn.com/image/Art/2DItems/Maps/PoorjoysAsylum.png" )
        , ( "Arena", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Arena.png" )
        , ( "Museum", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Museum.png" )
        , ( "The Putrid Cloister", "//web.poecdn.com/image/Art/2DItems/Maps/PutridCloister.png" )
        , ( "Scriptorium", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Scriptorium.png" )
        , ( "Siege", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Boulevard.png" )
        , ( "Shipyard", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Shipyard.png" )
        , ( "Belfry", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Belfry.png" )
        , ( "Arachnid Tomb", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Arachnid.png" )
        , ( "Wasteland", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Wasteland.png" )
        , ( "Precinct", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Precinct.png" )
        , ( "Bog", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Bog.png" )
        , ( "Pier", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Pier.png" )
        , ( "Cursed Crypt", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Crypt.png" )
        , ( "Orchard", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Orchard.png" )
        , ( "Promenade", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Promenade.png" )
        , ( "Hall of Grandmasters", "//web.poecdn.com/image/Art/2DItems/Maps/HallOfGrandmasters.png" )
        , ( "Lair", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Lair.png" )
        , ( "Colonnade", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Colonnade.png" )
        , ( "Primordial Pool", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/PrimordialPool.png" )
        , ( "Spider Forest", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/SpiderForest.png" )
        , ( "Coves", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Coves.png" )
        , ( "Waterways", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Waterways.png" )
        , ( "Factory", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Factory.png" )
        , ( "Mesa", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Mesa.png" )
        , ( "Pit", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Pit1.png" )
        , ( "Defiled Cathedral", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/DefiledCathedral.png" )
        , ( "Summit", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Summit.png" )
        , ( "Overgrown Shrine", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/OvergrownShrine.png" )
        , ( "Acton's Nightmare", "//web.poecdn.com/image/Art/2DItems/Maps/musicbox.png" )
        , ( "Castle Ruins", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/CastleRuins.png" )
        , ( "Crystal Ore", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/CrystalOre.png" )
        , ( "Villa", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Villa.png" )
        , ( "Primordial Blocks", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/PrimevalRuins.png" )
        , ( "Oba's Cursed Trove", "//web.poecdn.com/image/Art/2DItems/Maps/oba.png" )
        , ( "Necropolis", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Necropolis.png" )
        , ( "Death and Taxes", "//web.poecdn.com/image/Art/2DItems/Maps/DeathandTaxes.png" )
        , ( "Racecourse", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Racecourse.png" )
        , ( "Caldera", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Abyss.png" )
        , ( "Ghetto", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Ghetto.png" )
        , ( "Park", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Park.png" )
        , ( "Malformation", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Malformation.png" )
        , ( "Terrace", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/HighGardens.png" )
        , ( "Shrine", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Shrine.png" )
        , ( "Arsenal", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Arsenal.png" )
        , ( "Desert Spring", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Oasis.png" )
        , ( "Core", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Core.png" )
        , ( "Colosseum", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Colosseum.png" )
        , ( "Acid Caverns", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/SulphurVents.png" )
        , ( "Dark Forest", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/DarkForest.png" )
        , ( "Crimson Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Sanctuary.png" )
        , ( "Plaza", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Plaza.png" )
        , ( "Dig", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Dig.png" )
        , ( "Palace", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Palace.png" )
        , ( "Lava Lake", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Corpse.png" )
        , ( "Basilica", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Basilica.png" )
        , ( "Sunken City", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/SunkenCity.png" )
        , ( "Reef", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Reef.png" )
        , ( "Carcass", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Carcass.png" )
        , ( "Pit of the Chimera", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Chimera.png" )
        , ( "Lair of the Hydra", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Hydra.png" )
        , ( "Maze of the Minotaur", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Minotaur.png" )
        , ( "Forge of the Phoenix", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Phoenix.png" )
        , ( "Vaal Temple", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/VaalTempleBase.png" )
        , ( "Arachnid Tomb", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Arachnid.png" )
        , ( "Lava Lake", "//web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/Corpse.png" )
        ]


zoneAliases =
    -- support foreign zone names. Ideally we'd have the interface in other languages too, but this is easy to implement.
    -- chinese from https://docs.google.com/spreadsheets/d/1CsuY6jHhg38qu9k--zlUNTK-AjY5nDPbiFULBM9Uvtw/edit#gid=0
    [ ( "如履危牆", "Lookout" )
    , ( "白沙灘頭", "Beach" )
    , ( "墮影墓場", "Graveyard" )
    , ( "禁魂炎獄", "Dungeon" )
    , ( "危城巷弄", "Alleyways" )
    , ( "穢陰獄牢", "Pen" )
    , ( "貧瘠之地", "Desert" )
    , ( "乾枯湖岸", "Arid Lake" )
    , ( "洪災礦坑", "Flooded Mine" )
    , ( "惡臭沼地", "Marshes" )
    , ( "極原冰帽", "Iceberg" )
    , ( "羈破牢籠", "Cage" )
    , ( "奇術之泉", "Fungal Hollow" )
    , ( "挖掘場", "Excavation" )
    , ( "荒涼牧野", "Leyline" )
    , ( "乾潮林地", "Peninsula" )
    , ( "失落城塢", "Port" )
    , ( "旱地墓室", "Burial Chambers" )
    , ( "幽魂監牢", "Cells" )
    , ( "崩壞長廊", "Arcade" )
    , ( "危城廣場", "City Square" )
    , ( "古典密室", "Relic Chambers" )
    , ( "失序教院", "Courthouse" )
    , ( "致命岩灘", "Strand" )
    , ( "禁閉祭壇", "Whakawairua Tuahu" )
    , ( "古堡", "Chateau" )
    , ( "幽暗地穴", "Grotto" )
    , ( "烈陽山丘", "Glacier" )
    , ( "火山炎域", "Volcano" )
    , ( "絕望燈塔", "Lighthouse" )
    , ( "炙陽峽谷", "Canyon" )
    , ( "寧逸溫房", "Conservatory" )
    , ( "硫磺蝕岸", "Sulphur Vents" )
    , ( "幽魂宅邸", "Haunted Mansion" )
    , ( "冥神之域", "Maze" )
    , ( "秘密通道", "Channel" )
    , ( "腐敗下水道", "Toxic Sewer" )
    , ( "遠古危城", "Ancient City" )
    , ( "象牙神殿", "Ivory Temple" )
    , ( "巨蛛巢穴", "Spider Lair" )
    , ( "熱林塚墓", "Barrows" )
    , ( "靜縊陵墓", "Mausoleum" )
    , ( "無疆田野", "Fields" )
    , ( "劇毒林谷", "Jungle Valley" )
    , ( "魔靈幻獄", "Phantasmagoria" )
    , ( "惡靈學院", "Academy" )
    , ( "驚懼樹叢", "Thicket" )
    , ( "毒牙海港", "Wharf" )
    , ( "旱木林地", "Ashen Wood" )
    , ( "濱海山丘", "Atoll" )
    , ( "混沌之淵", "Maelström of Chaos" )
    , ( "晨曦墓地", "Cemetery" )
    , ( "萬聖之地", "Hallowed Ground" )
    , ( "濱海幽穴", "Underground Sea" )
    , ( "喧囂判庭", "Crater" )
    , ( "破碎堡礁", "Coral Ruins" )
    , ( "熔岩之室", "Lava Chamber" )
    , ( "神主居所", "Residence" )
    , ( "濱海堡壘", "Ramparts" )
    , ( "暮色沙丘", "Dunes" )
    , ( "艾倫之柱", "Pillars of Arun" )
    , ( "骨跡陵墓", "Bone Crypt" )
    , ( "雙炎修道院", "Convent of the Twins' Flame" )
    , ( "地底之河", "Underground River" )
    , ( "塞爾．佈雷德狼穴", "Caer Blaidd, Wolfpack's Den" )
    , ( "迷宮花園", "Gardens" )
    , ( "異蛛巢穴", "Arachnid Nest" )
    , ( "遠古市集", "Bazaar" )
    , ( "實驗居所", "Laboratory" )
    , ( "病疫林谷", "Infested Valley" )
    , ( "長草遺跡", "Overgrown Ruin" )
    , ( "瓦爾金字塔", "Vaal Pyramid" )
    , ( "阿茲里的秘寶庫", "Vaults of Atziri" )
    , ( "詭譎晶洞", "Geode" )
    , ( "軍械庫", "Armoury" )
    , ( "奇術之庭", "Courtyard" )
    , ( "維克塔廣場", "The Vinktar Square" )
    , ( "陰晦泥灘", "Mud Geyser" )
    , ( "暮光海灘", "Shore" )
    , ( "賊窩", "Mao Kun" )
    , ( "晴空幽島", "Tropical Island" )
    , ( "濕地礦山", "Mineral Pools" )
    , ( "嬋娟神殿", "Moon Temple" )
    , ( "暮色神廟", "The Twilight Temple" )
    , ( "陰暗墓塚", "Sepulchre" )
    , ( "闇獄尖塔", "Tower" )
    , ( "死寂泥溝", "Waste Pool" )
    , ( "海風高原", "Plateau" )
    , ( "熔火岩灘", "Estuary" )
    , ( "魔金寶庫", "Vault" )
    , ( "奪魂之殿", "Temple" )
    , ( "沉淪之間", "Poorjoy's Asylum" )
    , ( "競技場", "Arena" )
    , ( "古博物館", "Museum" )
    , ( "腐臭迴廊", "The Putrid Cloister" )
    , ( "墓影書坊", "Scriptorium" )
    , ( "禁斷圍城", "Siege" )
    , ( "熾炎船塢", "Shipyard" )
    , ( "雲頂鐘樓", "Belfry" )
    , ( "異蛛墓塚", "Arachnid Tomb" )
    , ( "荒地", "Wasteland" )
    , ( "苦行之域", "Precinct" )
    , ( "瘴氣泥沼", "Bog" )
    , ( "怒浪之港", "Pier" )
    , ( "惡咒陵墓", "Cursed Crypt" )
    , ( "懦者的試驗", "The Coward's Trial" )
    , ( "密林果園", "Orchard" )
    , ( "月色迴廊", "Promenade" )
    , ( "元帥殿堂", "Hall of Grandmasters" )
    , ( "餓獸巢穴", "Lair" )
    , ( "激戰柱廊", "Colonnade" )
    , ( "血腥沼澤", "Primordial Pool" )
    , ( "巨蛛之林", "Spider Forest" )
    , ( "疾風峽灣", "Coves" )
    , ( "危機水道", "Waterways" )
    , ( "鐵鏽工廠", "Factory" )
    , ( "平頂荒漠", "Mesa" )
    , ( "巨坑", "Pit" )
    , ( "不潔教堂", "Defiled Cathedral" )
    , ( "寒頂之巔", "Summit" )
    , ( "密草神殿", "Overgrown Shrine" )
    , ( "輪迴的夢魘", "Acton's Nightmare" )
    , ( "遺跡廢墟", "Castle Ruins" )
    , ( "紫晶礦山", "Crystal Ore" )
    , ( "魅影別墅", "Villa" )
    , ( "古拷刑室", "Primordial Blocks" )
    , ( "歐霸的咒怨寶庫", "Oba's Cursed Trove" )
    , ( "魔影墓場", "Necropolis" )
    , ( "亡者之財", "Death and Taxes" )
    , ( "古競速場", "Racecourse" )
    , ( "火山炎口", "Caldera" )
    , ( "赤貧居所", "Ghetto" )
    , ( "園林苑", "Park" )
    , ( "畸形亡域", "Malformation" )
    , ( "露台花園", "Terrace" )
    , ( "奇術秘殿", "Shrine" )
    , ( "古兵工廠", "Arsenal" )
    , ( "硫磺荒漠", "Desert Spring" )
    , ( "核心", "Core" )
    , ( "小決鬥場", "Colosseum" )
    , ( "尖酸苛泊", "Acid Caverns" )
    , ( "夜語幽林", "Dark Forest" )
    , ( "緋紅神殿", "Crimson Temple" )
    , ( "廣場", "Plaza" )
    , ( "違禁掘坑", "Dig" )
    , ( "神域之殿", "Palace" )
    , ( "岩漿熔湖", "Lava Lake" )
    , ( "聖殿", "Basilica" )
    , ( "亞特蘭提斯", "Sunken City" )
    , ( "危機海礁", "Reef" )
    , ( "惡臭屍域", "Carcass" )
    , ( "奇美拉魔坑", "Pit of the Chimera" )
    , ( "九頭蛇冰窟", "Lair of the Hydra" )
    , ( "牛頭人謎域", "Maze of the Minotaur" )
    , ( "火鳳凰熔核", "Forge of the Phoenix" )
    , ( "瓦爾密殿", "Vaal Temple" )
    , ( "塑者之界", "The Shaper's Realm" )
    , ( "誘人的深淵", "The Alluring Abyss" )
    , ( "生贄之尖", "The Apex of Sacrifice" )
    , ( "獅眼守望", "Lioneye's Watch" )
    , ( "森林營地", "The Forest Encampment" )
    , ( "薩恩營地", "The Sarn Encampment" )
    , ( "統治者之殿", "Highgate" )
    , ( "監守高塔", "Overseer's Tower" )
    , ( "獅眼守望", "Lioneye's Watch" )
    , ( "橋墩營地", "The Bridge Encampment" )
    , ( "薩恩營地", "The Sarn Encampment" )
    , ( "統治者之殿", "Highgate" )
    , ( "奧瑞亞港口", "Oriath Docks" )
    , ( "奧瑞亞", "Oriath" )
    , ( "藏身處 - 樹林（小）", "Unearthed Hideout" )
    , ( "藏身處 - 圖書館（小）", "Enlightened Hideout" )
    , ( "藏身處 - 海岸（小）", "Coastal Hideout" )
    , ( "藏身處 - 花園（小）", "Overgrown Hideout" )
    , ( "藏身處 - 樹林（小）", "Lush Hideout" )
    , ( "藏身處 - 戰場遺跡（小）", "Battle-scarred Hideout" )
    , ( "藏身處 - 貧民窟（小）", "Backstreet Hideout" )
    , ( "藏身處 - 日耀神殿（小）", "Immaculate Hideout" )
    , ( "藏身處 - 樹林（中）", "Unearthed Hideout" )
    , ( "藏身處 - 圖書館（中）", "Enlightened Hideout" )
    , ( "藏身處 - 海岸（中）", "Coastal Hideout" )
    , ( "藏身處 - 花園（中）", "Overgrown Hideout" )
    , ( "藏身處 - 樹林（中）", "Lush Hideout" )
    , ( "藏身處 - 戰場遺跡（中）", "Battle-scarred Hideout" )
    , ( "藏身處 - 貧民窟（中）", "Backstreet Hideout" )
    , ( "藏身處 - 日耀神殿（中）", "Immaculate Hideout" )
    , ( "藏身處 - 樹林（大）", "Unearthed Hideout" )
    , ( "藏身處 - 圖書館（大）", "Enlightened Hideout" )
    , ( "藏身處 - 海岸（大）", "Coastal Hideout" )
    , ( "藏身處 - 花園（大）", "Overgrown Hideout" )
    , ( "藏身處 - 樹林（大）", "Lush Hideout" )
    , ( "藏身處 - 戰場遺跡（大）", "Battle-scarred Hideout" )
    , ( "藏身處 - 貧民窟（大）", "Backstreet Hideout" )
    , ( "藏身處 - 日耀神殿（大）", "Immaculate Hideout" )

    -- fix #32 - I messed up the map name the first time. Easier to add an alias than change it everywhere.
    , ( "The Hall of Grandmasters", "Hall of Grandmasters" )
    ]
