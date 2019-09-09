module Mapwatch.MapList exposing (Map, mapList, url, zoneAliases, zoneAliasesDict)

import Dict exposing (Dict)
import Maybe.Extra
import Regex exposing (Regex)
import Set exposing (Set)


type alias Map =
    { name : String, tier : Int, unique : Bool }


zoneAliasesDict =
    Dict.fromList zoneAliases


englishMapsByName : Result String (Dict String Map)
englishMapsByName =
    englishMapList
        |> Result.map
            (List.map (\m -> ( m.name, m ))
                >> Dict.fromList
            )


mapList : Result String (List Map)
mapList =
    Result.map2
        (\list byName ->
            let
                buildAlias nonenglish english =
                    Dict.get english byName |> Maybe.map (\m -> { m | name = nonenglish })
            in
            list ++ (List.map (\( a, b ) -> buildAlias a b) zoneAliases |> Maybe.Extra.values)
        )
        englishMapList
        englishMapsByName


mapsByName : Result String (Dict String Map)
mapsByName =
    Result.map (List.map (\m -> ( m.name, m )) >> Dict.fromList) mapList


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
        (mapsByName |> Result.withDefault Dict.empty |> Dict.get name)
        (Dict.get name urlNames)
        |> Maybe.map ((++) "https:")


specialUrlNames =
    -- thanks, https://poecraft.com/atlas and #/debug/mapicons
    -- and https://poecraft.com/js/app/generated/atlasmaps.js?v=5dc7fdae
    -- and http://poedb.tw/us/unique.php?cn=Map
    Dict.fromList
        -- these maps are in a separate poedb.tw section for some reason, filled in manually. http://poedb.tw/us/unique.php?cn=Map
        [ ( "Hallowed Ground", "//web.poecdn.com/image/Art/2DItems/Maps/HallowedGround.png" )
        , ( "The Coward's Trial", "//web.poecdn.com/image/Art/2DItems/Maps/UndeadSiege.png" )
        , ( "Mao Kun", "//web.poecdn.com/image/Art/2DItems/Maps/FairgravesMap01.png" )
        , ( "Untainted Paradise", "//web.poecdn.com/image/Art/2DItems/Maps/UniqueMap2.png" )
        , ( "Olmec's Sanctum", "//web.poecdn.com/image/Art/2DItems/Maps/olmec.png" )
        , ( "Perandus Manor", "//web.poecdn.com/image/Art/2DItems/Maps/PerandusManor.png" )
        , ( "Doryani's Machinarium", "//web.poecdn.com/image/Art/2DItems/Maps/Doryanis.png" )

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
    , { name = "The Beachhead", tier = 5, unique = True }
    , { name = "The Beachhead", tier = 10, unique = True }
    , { name = "The Beachhead", tier = 15, unique = True }
    ]


englishMapList : Result String (List Map)
englishMapList =
    Result.map ((++) specialMapList) extractedMapList


{-| maps grouped by tier
-}
extractedMapList : Result String (List Map)
extractedMapList =
    let
        build tier name =
            { name = name
            , tier = tier
            , unique = Set.member name uniqueMapNames
            }
    in
    blightMapList
        |> List.map (\( tier, names ) -> names |> List.map (build tier))
        |> List.concat
        |> assertMapLists legionExtractedMapList


assertMapLists : List Map -> List Map -> Result String (List Map)
assertMapLists expected actual =
    let
        nameuniq m =
            -- bools aren't comparables? seriously, elm?
            ( m.name
            , if m.unique then
                1

              else
                0
            )

        nameuniqs : List Map -> Set ( String, Int )
        nameuniqs =
            List.map nameuniq >> Set.fromList

        diff =
            nameuniqs actual |> Set.diff (nameuniqs expected)
    in
    if Set.isEmpty diff then
        Ok actual

    else
        Err <| "seasonal map names/uniques are different: " ++ Debug.toString diff


blightMapList : List ( Int, List String )
blightMapList =
    [ -- special maps, not extracted from GGG's list
      ( 5, [ "Untainted Paradise", "The Beachhead" ] )
    , ( 10, [ "The Beachhead" ] )
    , ( 15, [ "The Beachhead" ] )

    -- Built from reading https://www.reddit.com/r/pathofexile/comments/cx82nl/heres_a_preview_of_the_atlas_of_worlds_in_path_of/
    -- Previously we constructed `Map`s inline, but this way is easier to extract from GGG's list.
    -- Tiers are explicitly listed because it's less prone to typos than list indexes.
    , ( 1
      , [ "Arcade"
        , "Jungle Valley"
        , "Wharf"
        , "Pier"
        ]
      )
    , ( 2
      , [ "Alleyways"
        , "Cage"
        , "Excavation"
        , "Sulphur Vents"
        , "Armoury"
        , "Mesa"
        ]
      )
    , ( 3
      , [ "Pen"
        , "Desert"
        , "Fungal Hollow"
        , "Strand"
        , "Ivory Temple"
        , "Spider Lair"
        , "Mausoleum"
        , "Ashen Wood"
        , "Ramparts"
        , "Tropical Island"
        , "Whakawairua Tuahu"
        ]
      )
    , ( 4
      , [ "Arid Lake"
        , "Flooded Mine"
        , "Leyline"
        , "Burial Chambers"
        , "Channel"
        , "Barrows"
        , "Fields"
        , "Crater"
        , "Arachnid Tomb"
        , "Cursed Crypt"
        , "The Coward's Trial"
        ]
      )
    , ( 5
      , [ "Lookout"
        , "Beach"
        , "Marshes"
        , "Peninsula"
        , "City Square"
        , "Relic Chambers"
        , "Grotto"
        , "Glacier"
        , "Haunted Mansion"
        , "Thicket"
        ]
      )
    , ( 6
      , [ "Lighthouse"
        , "Maze"
        , "Residence"
        , "Bone Crypt"
        , "Geode"
        , "Estuary"
        , "Vault"
        , "Overgrown Shrine"
        , "Racecourse"
        , "Ghetto"
        , "Arsenal"
        , "Doryani's Machinarium"
        , "Olmec's Sanctum"
        , "Acton's Nightmare"
        ]
      )
    , ( 7
      , [ "Port"
        , "Chateau"
        , "Conservatory"
        , "Ancient City"
        , "Underground Sea"
        , "Bazaar"
        , "Waste Pool"
        , "Spider Forest"
        , "Factory"
        , "Villa"
        , "Necropolis"
        , "Perandus Manor"
        , "Oba's Cursed Trove"
        , "Death and Taxes"
        ]
      )
    , ( 8
      , [ "Graveyard"
        , "Cells"
        , "Volcano"
        , "Phantasmagoria"
        , "Atoll"
        , "Underground River"
        , "Arachnid Nest"
        , "Shore"
        , "Sepulchre"
        , "Temple"
        , "Pit"
        , "Maelström of Chaos"
        , "Caer Blaidd, Wolfpack's Den"
        , "Mao Kun"
        , "Poorjoy's Asylum"
        ]
      )
    , ( 9
      , [ "Dungeon"
        , "Coral Ruins"
        , "Laboratory"
        , "Courtyard"
        , "Mud Geyser"
        , "Mineral Pools"
        , "Arena"
        , "Scriptorium"
        , "Promenade"
        , "Waterways"
        , "Castle Ruins"
        , "The Vinktar Square"
        , "Hall of Grandmasters"
        ]
      )
    , ( 10
      , [ "Iceberg"
        , "Toxic Sewer"
        , "Academy"
        , "Lava Chamber"
        , "Dunes"
        , "Overgrown Ruin"
        , "Moon Temple"
        , "Plateau"
        , "Bog"
        , "Primordial Pool"
        , "Pillars of Arun"
        , "The Twilight Temple"
        ]
      )
    , ( 11
      , [ "Gardens"
        , "Vaal Pyramid"
        , "Tower"
        , "Lair"
        , "Caldera"
        , "Park"
        , "Shrine"
        , "Palace"
        , "Sunken City"
        , "Reef"
        , "Vaults of Atziri"
        ]
      )
    , ( 12
      , [ "Courthouse"
        , "Cemetery"
        , "Shipyard"
        , "Belfry"
        , "Crystal Ore"
        , "Malformation"
        , "Desert Spring"
        , "Plaza"
        , "Dig"
        , "Hallowed Ground"
        ]
      )
    , ( 13
      , [ "Infested Valley"
        , "Museum"
        , "Wasteland"
        , "Precinct"
        , "Orchard"
        , "Acid Caverns"
        , "Crimson Temple"
        , "Basilica"
        , "Carcass"
        , "The Putrid Cloister"
        ]
      )
    , ( 14
      , [ "Defiled Cathedral"
        , "Summit"
        , "Primordial Blocks"
        , "Terrace"
        , "Core"
        , "Colosseum"
        , "Lava Lake"
        ]
      )
    , ( 15
      , [ "Canyon"
        , "Siege"
        , "Colonnade"
        , "Coves"
        , "Dark Forest"
        ]
      )
    , ( 16
      , [ "Pit of the Chimera"
        , "Lair of the Hydra"
        , "Maze of the Minotaur"
        , "Forge of the Phoenix"
        , "Vaal Temple"
        ]
      )
    ]


legionExtractedMapList =
    -- Built from reading https://www.reddit.com/r/pathofexile/comments/bwhiyi/heres_a_preview_of_the_atlas_of_worlds_in_path_of/epxlf0g/
    [ { name = "Sulphur Vents", tier = 1, unique = False }
    , { name = "Haunted Mansion", tier = 1, unique = False }
    , { name = "Desert", tier = 1, unique = False }
    , { name = "Ivory Temple", tier = 1, unique = False }
    , { name = "Glacier", tier = 2, unique = False }
    , { name = "Thicket", tier = 2, unique = False }
    , { name = "Alleyways", tier = 2, unique = False }
    , { name = "Lookout", tier = 2, unique = False }
    , { name = "Barrows", tier = 2, unique = False }
    , { name = "Armoury", tier = 2, unique = False }
    , { name = "Leyline", tier = 3, unique = False }
    , { name = "Mausoleum", tier = 3, unique = False }
    , { name = "Ashen Wood", tier = 3, unique = False }
    , { name = "Relic Chambers", tier = 3, unique = False }
    , { name = "Pier", tier = 3, unique = False }
    , { name = "Arid Lake", tier = 3, unique = False }
    , { name = "Arachnid Tomb", tier = 3, unique = False }
    , { name = "Flooded Mine", tier = 3, unique = False }
    , { name = "Wharf", tier = 3, unique = False }
    , { name = "Pen", tier = 3, unique = False }
    , { name = "Excavation", tier = 4, unique = False }
    , { name = "Crater", tier = 4, unique = False }
    , { name = "City Square", tier = 4, unique = False }
    , { name = "Fields", tier = 4, unique = False }
    , { name = "Cage", tier = 4, unique = False }
    , { name = "Grotto", tier = 4, unique = False }
    , { name = "Cursed Crypt", tier = 4, unique = False }
    , { name = "Strand", tier = 4, unique = False }
    , { name = "Channel", tier = 4, unique = False }
    , { name = "Beach", tier = 4, unique = False }
    , { name = "Marshes", tier = 5, unique = False }
    , { name = "Spider Lair", tier = 5, unique = False }
    , { name = "Tropical Island", tier = 5, unique = False }
    , { name = "Ramparts", tier = 5, unique = False }
    , { name = "Burial Chambers", tier = 5, unique = False }
    , { name = "Mesa", tier = 5, unique = False }
    , { name = "Jungle Valley", tier = 5, unique = False }
    , { name = "Peninsula", tier = 5, unique = False }
    , { name = "Arcade", tier = 5, unique = False }
    , { name = "Fungal Hollow", tier = 5, unique = False }
    , { name = "Mud Geyser", tier = 6, unique = False }
    , { name = "Courtyard", tier = 6, unique = False }
    , { name = "Ancient City", tier = 6, unique = False }
    , { name = "Atoll", tier = 6, unique = False }
    , { name = "Maze", tier = 6, unique = False }
    , { name = "Promenade", tier = 6, unique = False }
    , { name = "Cells", tier = 6, unique = False }
    , { name = "Phantasmagoria", tier = 6, unique = False }
    , { name = "Waste Pool", tier = 6, unique = False }
    , { name = "Overgrown Ruin", tier = 6, unique = False }
    , { name = "Primordial Pool", tier = 6, unique = False }
    , { name = "Residence", tier = 7, unique = False }
    , { name = "Spider Forest", tier = 7, unique = False }
    , { name = "Arena", tier = 7, unique = False }
    , { name = "Dungeon", tier = 7, unique = False }
    , { name = "Racecourse", tier = 7, unique = False }
    , { name = "Graveyard", tier = 7, unique = False }
    , { name = "Vault", tier = 7, unique = False }
    , { name = "Waterways", tier = 7, unique = False }
    , { name = "Conservatory", tier = 7, unique = False }
    , { name = "Laboratory", tier = 7, unique = False }
    , { name = "Overgrown Shrine", tier = 7, unique = False }
    , { name = "Iceberg", tier = 8, unique = False }
    , { name = "Pit", tier = 8, unique = False }
    , { name = "Ghetto", tier = 8, unique = False }
    , { name = "Bone Crypt", tier = 8, unique = False }
    , { name = "Chateau", tier = 8, unique = False }
    , { name = "Toxic Sewer", tier = 8, unique = False }
    , { name = "Scriptorium", tier = 8, unique = False }
    , { name = "Dunes", tier = 8, unique = False }
    , { name = "Factory", tier = 8, unique = False }
    , { name = "Necropolis", tier = 8, unique = False }
    , { name = "Estuary", tier = 8, unique = False }
    , { name = "Arachnid Nest", tier = 9, unique = False }
    , { name = "Port", tier = 9, unique = False }
    , { name = "Villa", tier = 9, unique = False }
    , { name = "Mineral Pools", tier = 9, unique = False }
    , { name = "Underground River", tier = 9, unique = False }
    , { name = "Underground Sea", tier = 9, unique = False }
    , { name = "Castle Ruins", tier = 9, unique = False }
    , { name = "Shore", tier = 9, unique = False }
    , { name = "Moon Temple", tier = 9, unique = False }
    , { name = "Arsenal", tier = 9, unique = False }
    , { name = "Lighthouse", tier = 9, unique = False }
    , { name = "Sepulchre", tier = 10, unique = False }
    , { name = "Coral Ruins", tier = 10, unique = False }
    , { name = "Volcano", tier = 10, unique = False }
    , { name = "Geode", tier = 10, unique = False }
    , { name = "Bog", tier = 10, unique = False }
    , { name = "Plateau", tier = 10, unique = False }
    , { name = "Lava Chamber", tier = 10, unique = False }
    , { name = "Bazaar", tier = 10, unique = False }
    , { name = "Academy", tier = 10, unique = False }
    , { name = "Temple", tier = 10, unique = False }
    , { name = "Infested Valley", tier = 11, unique = False }
    , { name = "Dig", tier = 11, unique = False }
    , { name = "Lair", tier = 11, unique = False }
    , { name = "Malformation", tier = 11, unique = False }
    , { name = "Siege", tier = 11, unique = False }
    , { name = "Gardens", tier = 11, unique = False }
    , { name = "Crimson Temple", tier = 11, unique = False }
    , { name = "Precinct", tier = 11, unique = False }
    , { name = "Colonnade", tier = 11, unique = False }
    , { name = "Museum", tier = 11, unique = False }
    , { name = "Lava Lake", tier = 12, unique = False }
    , { name = "Cemetery", tier = 12, unique = False }
    , { name = "Vaal Pyramid", tier = 12, unique = False }
    , { name = "Park", tier = 12, unique = False }
    , { name = "Shipyard", tier = 12, unique = False }
    , { name = "Core", tier = 12, unique = False }
    , { name = "Carcass", tier = 12, unique = False }
    , { name = "Canyon", tier = 12, unique = False }
    , { name = "Colosseum", tier = 12, unique = False }
    , { name = "Tower", tier = 13, unique = False }
    , { name = "Sunken City", tier = 13, unique = False }
    , { name = "Defiled Cathedral", tier = 13, unique = False }
    , { name = "Belfry", tier = 13, unique = False }
    , { name = "Coves", tier = 13, unique = False }
    , { name = "Shrine", tier = 13, unique = False }
    , { name = "Plaza", tier = 13, unique = False }
    , { name = "Terrace", tier = 13, unique = False }
    , { name = "Reef", tier = 13, unique = False }
    , { name = "Primordial Blocks", tier = 14, unique = False }
    , { name = "Orchard", tier = 14, unique = False }
    , { name = "Wasteland", tier = 14, unique = False }
    , { name = "Crystal Ore", tier = 14, unique = False }
    , { name = "Courthouse", tier = 14, unique = False }
    , { name = "Basilica", tier = 14, unique = False }
    , { name = "Dark Forest", tier = 14, unique = False }
    , { name = "Summit", tier = 15, unique = False }
    , { name = "Caldera", tier = 15, unique = False }
    , { name = "Acid Caverns", tier = 15, unique = False }
    , { name = "Desert Spring", tier = 15, unique = False }
    , { name = "Palace", tier = 15, unique = False }
    , { name = "Vaal Temple", tier = 16, unique = False }
    , { name = "Forge of the Phoenix", tier = 16, unique = False }
    , { name = "Maze of the Minotaur", tier = 16, unique = False }
    , { name = "Pit of the Chimera", tier = 16, unique = False }
    , { name = "Lair of the Hydra", tier = 16, unique = False }
    ]
        ++ legionUniqueMapList


legionUniqueMapList =
    -- OLD - delete this soon
    [ { name = "Whakawairua Tuahu", tier = 4, unique = True }
    , { name = "The Coward's Trial", tier = 4, unique = True }
    , { name = "Untainted Paradise", tier = 5, unique = True }
    , { name = "Hall of Grandmasters", tier = 6, unique = True }
    , { name = "Maelström of Chaos", tier = 6, unique = True }
    , { name = "The Vinktar Square", tier = 6, unique = True }
    , { name = "Doryani's Machinarium", tier = 6, unique = True }
    , { name = "Acton's Nightmare", tier = 7, unique = True }
    , { name = "Olmec's Sanctum", tier = 8, unique = True }
    , { name = "Perandus Manor", tier = 8, unique = True }
    , { name = "Pillars of Arun", tier = 8, unique = True }
    , { name = "Death and Taxes", tier = 8, unique = True }
    , { name = "Mao Kun", tier = 9, unique = True }
    , { name = "The Twilight Temple", tier = 9, unique = True }
    , { name = "Caer Blaidd, Wolfpack's Den", tier = 9, unique = True }
    , { name = "Oba's Cursed Trove", tier = 9, unique = True }
    , { name = "Poorjoy's Asylum", tier = 10, unique = True }
    , { name = "The Putrid Cloister", tier = 11, unique = True }
    , { name = "Hallowed Ground", tier = 12, unique = True }
    , { name = "Vaults of Atziri", tier = 12, unique = True }
    ]


uniqueMapNames : Set String
uniqueMapNames =
    [ "Whakawairua Tuahu"
    , "The Coward's Trial"
    , "Untainted Paradise"
    , "Hall of Grandmasters"
    , "Maelström of Chaos"
    , "The Vinktar Square"
    , "Doryani's Machinarium"
    , "Acton's Nightmare"
    , "Olmec's Sanctum"
    , "Perandus Manor"
    , "Pillars of Arun"
    , "Death and Taxes"
    , "Mao Kun"
    , "The Twilight Temple"
    , "Caer Blaidd, Wolfpack's Den"
    , "Oba's Cursed Trove"
    , "Poorjoy's Asylum"
    , "The Putrid Cloister"
    , "Hallowed Ground"
    , "Vaults of Atziri"
    ]
        |> Set.fromList


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
    -- and https://docs.google.com/spreadsheets/d/1zakVv3EO4xIKJCP2ZlU2KE_kTg-tt1kgx3X5vO5E-24/edit#gid=0
    --
    -- maps
    [ ( "貧瘠之地", "Desert" )
    , ( "幽魂宅邸", "Haunted Mansion" )
    , ( "象牙神殿", "Ivory Temple" )
    , ( "硫磺蝕岸", "Sulphur Vents" )
    , ( "危城巷弄", "Alleyways" )
    , ( "軍械庫", "Armoury" )
    , ( "熱林塚墓", "Barrows" )
    , ( "冰川山丘", "Glacier" )
    , ( "如履危牆", "Lookout" )
    , ( "驚懼樹叢", "Thicket" )
    , ( "異蛛墓塚", "Arachnid Tomb" )
    , ( "乾枯湖岸", "Arid Lake" )
    , ( "旱木林地", "Ashen Wood" )
    , ( "洪災礦坑", "Flooded Mines" )
    , ( "荒涼牧野", "Leyline" )
    , ( "靜縊陵墓", "Mausoleum" )
    , ( "穢陰獄牢", "Pen" )
    , ( "怒浪之港", "Pier" )
    , ( "古典密室", "Relic Chambers" )
    , ( "毒牙海港", "Wharf" )
    , ( "白沙灘頭", "Beach" )
    , ( "羈破牢籠", "Cage" )
    , ( "秘密通道", "Channel" )
    , ( "危城廣場", "City Square" )
    , ( "殘破殞坑", "Crater" )
    , ( "惡咒陵墓", "Cursed Crypt" )
    , ( "挖掘場", "Excavation" )
    , ( "無疆田野", "Fields" )
    , ( "幽暗地穴", "Grotto" )
    , ( "致命岩灘", "Strand" )
    , ( "崩壞長廊", "Arcade" )
    , ( "旱地墓室", "Burial Chambers" )
    , ( "毒菌魔域", "Fungal Hollow" )
    , ( "劇毒林谷", "Jungle Valley" )
    , ( "惡臭沼地", "Marshes" )
    , ( "平頂荒漠", "Mesa" )
    , ( "乾潮林地", "Peninsula" )
    , ( "濱海堡壘", "Ramparts" )
    , ( "巨蛛巢穴", "Spider Lair" )
    , ( "晴空幽島", "Tropical Island" )
    , ( "遠古危城", "Ancient City" )
    , ( "濱海山丘", "Atoll" )
    , ( "幽魂監牢", "Cells" )
    , ( "奇術之庭", "Courtyard" )
    , ( "冥神之域", "Maze" )
    , ( "陰晦泥灘", "Mud Geyser" )
    , ( "長草遺跡", "Overgrown Ruins" )
    , ( "魔靈幻獄", "Phantasmagoria" )
    , ( "血腥沼澤", "Primordial Pool" )
    , ( "月色迴廊", "Promenade" )
    , ( "死寂泥溝", "Waste Pool" )
    , ( "競技場", "Arena" )
    , ( "寧逸溫房", "Conservatory" )
    , ( "禁魂炎獄", "Dungeon" )
    , ( "墮影墓場", "Graveyard" )
    , ( "實驗居所", "Laboratory" )
    , ( "密草神殿", "Overgrown Shrine" )
    , ( "古競速場", "Racecourse" )
    , ( "神主居所", "Residence" )
    , ( "巨蛛之林", "Spider Forest" )
    , ( "魔金寶庫", "Vault" )
    , ( "危機水道", "Waterways" )
    , ( "骨跡陵墓", "Bone Crypt" )
    , ( "古堡", "Chateau" )
    , ( "暮色沙丘", "Dunes" )
    , ( "熔火岩灘", "Estuary" )
    , ( "鐵鏽工廠", "Factory" )
    , ( "赤貧居所", "Ghetto" )
    , ( "極原冰帽", "Iceberg" )
    , ( "魔影墓場", "Necropolis" )
    , ( "巨坑", "Pit" )
    , ( "墓影書坊", "Scriptorium" )
    , ( "腐敗下水道", "Toxic Sewer" )
    , ( "異蛛巢穴", "Arachnid Nest" )
    , ( "古兵工廠", "Arsenal" )
    , ( "遺跡廢墟", "Castle Ruins" )
    , ( "絕望燈塔", "Lighthouse" )
    , ( "濕地礦山", "Mineral Pools" )
    , ( "嬋娟神殿", "Moon Temple" )
    , ( "失落城塢", "Port" )
    , ( "暮光海灘", "Shore" )
    , ( "地底之河", "Underground River" )
    , ( "濱海幽穴", "Underground Sea" )
    , ( "魅影別墅", "Villa" )
    , ( "惡靈學院", "Academy" )
    , ( "遠古市集", "Bazaar" )
    , ( "瘴氣泥沼", "Bog" )
    , ( "破碎堡礁", "Coral Ruins" )
    , ( "詭譎晶洞", "Geode" )
    , ( "熔岩之室", "Lava chamber" )
    , ( "海風高原", "Plateau" )
    , ( "陰暗墓塚", "Sepulchre" )
    , ( "奪魂之殿", "Temple" )
    , ( "火山炎域", "Volcano" )
    , ( "激戰柱廊", "Colonnade" )
    , ( "緋紅神殿", "Crimson Temple" )
    , ( "違禁掘坑", "Dig" )
    , ( "迷宮花園", "Gardens" )
    , ( "病疫林谷", "Infested Valley" )
    , ( "餓獸巢穴", "Lair" )
    , ( "畸形亡域", "Malformation" )
    , ( "古博物館", "Museum" )
    , ( "苦行之域", "Precinct" )
    , ( "禁斷圍城", "Siege" )
    , ( "炙陽峽谷", "Canyon" )
    , ( "惡臭屍域", "Carcass" )
    , ( "晨曦墓地", "Cemetery" )
    , ( "大決鬥場", "Colosseum" )
    , ( "核心", "Core" )
    , ( "岩漿熔湖", "Lava Lake" )
    , ( "園林苑", "Park" )
    , ( "熾炎船塢", "Shipyard" )
    , ( "瓦爾金字塔", "Vaal Pyramid" )
    , ( "雲頂鐘樓", "Belfry" )
    , ( "疾風峽灣", "Coves" )
    , ( "不潔教堂", "Defiled Cathedral" )
    , ( "廣場", "Plaza" )
    , ( "危機海礁", "Reef" )
    , ( "奇術秘殿", "Shrine" )
    , ( "亞特蘭提斯", "Sunken City" )
    , ( "露台花園", "Terrace" )
    , ( "闇獄尖塔", "Tower" )
    , ( "聖殿", "Basilica" )
    , ( "失序教院", "Courthouse" )
    , ( "紫晶礦山", "Crystal Ore" )
    , ( "夜語幽林", "Dark Forest" )
    , ( "密林果園", "Orchard" )
    , ( "血腥陣地", "Primordial Blocks" )
    , ( "荒地", "Wasteland" )
    , ( "酸岩酸嶼", "Acid Caverns" )
    , ( "火山炎口", "Caldera" )
    , ( "硫磺荒漠", "Desert Spring" )
    , ( "神域之殿", "Palace" )
    , ( "寒頂之巔", "Summit" )
    , ( "火鳳凰熔核", "Forge of the Phoenix" )
    , ( "九頭蛇冰窟", "Lair of the Hydra" )
    , ( "牛頭人謎域", "Maze of the Minotaur" )
    , ( "奇美拉魔坑", "Pit of the Chimera" )
    , ( "瓦爾密殿", "Vaal Temple" )
    , ( "懦者的試驗", "The Coward's Trial" )
    , ( "純淨樂園", "Untainted Paradise" )
    , ( "元帥殿堂", "Hall of Grandmasters" )
    , ( "混沌之淵", "Maelström of Chaos" )
    , ( "維克塔廣場", "The Vinktar Square" )
    , ( "多里亞尼的機械迷城", "Doryani's Machinarium" )
    , ( "輪迴的夢魘", "Acton's Nightmare" )
    , ( "遠古之印", "Olmec's Sanctum" )
    , ( "普蘭德斯莊園", "Perandus Manor" )
    , ( "艾倫之柱", "Pillars of Arun" )
    , ( "亡者之財", "Death and Taxes" )
    , ( "賊窩", "Mao Kun" )
    , ( "暮色神廟", "The Twilight Temple" )
    , ( "佈雷德狼穴", "Caer Blaidd, Wolfpack's Den" )
    , ( "歐霸的咒怨寶庫", "Oba's Cursed Trove" )
    , ( "沉淪之間", "Poorjoy's Asylum" )
    , ( "腐臭迴廊", "The Putrid Cloister" )
    , ( "萬聖之地", "Hallowed Ground" )
    , ( "阿茲里的秘寶庫", "Vaults of Atziri" )
    , ( "神諭之殿", "The Beachhead" )
    , ( "塑者之界", "The Shaper's Realm" )
    , ( "誘人的深淵", "The Alluring Abyss" )
    , ( "生贄之尖", "The Apex of Sacrifice" )

    -- towns
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

    -- hideouts
    , ( "藏身處 - 樹之棲所", "Arboreal Hideout" )
    , ( "藏身處 - 羅雀後街", "Backstreet Hideout" )
    , ( "藏身處 - 凶宅", "Baleful Hideout" )
    , ( "藏身處 - 槍痕彈域", "Battle -scarred Hideout" )
    , ( "藏身處 - 行刑室", "Brutal Hideout" )
    , ( "藏身處 - 繪圖室", "Cartographer's Hideout" )
    , ( "藏身處 - 絢麗眾星", "Celestial Hideout" )
    , ( "藏身處 - 王者榮耀", "Champion's Hideout" )
    , ( "藏身處 - 濱海之岸", "Coastal Hideout" )
    , ( "藏身處 - 珊瑚礁岸", "Coral Hideout" )
    , ( "藏身處 - 腐化密殿", "Corrupted Hideout" )
    , ( "藏身處 - 貧瘠之地", "Desert Hideout" )
    , ( "藏身處 - 暮光之殿", "Divided Hideout" )
    , ( "藏身處 - 厄夜衛士", "Doomguard Hideout" )
    , ( "藏身處 - 日月圓缺", "Eclipsed Hideout" )
    , ( "藏身處 - 啟蒙館", "Enlightened Hideout" )
    , ( "藏身處 - 礦坑", "Excavated Hideout" )
    , ( "藏身處 - 怒炎沖關", "Furious Hideout" )
    , ( "藏身處 - 凜凍冰川", "Glacial Hideout" )
    , ( "藏身處 - 微熠之森", "Glimmerwood Hideout" )
    , ( "藏身處 - 森幽莊園", "Haunted Hideout" )
    , ( "藏身處 - 無瑕之殿", "Immaculate Hideout" )
    , ( "藏身處 - 神主之殿", "Indomitable Hideout" )
    , ( "藏身處 - 善淨神殿", "Innocent Hideout" )
    , ( "藏身處 - 富饒之地", "Lush Hideout" )
    , ( "藏身處 - 奢華帝堡", "Luxurious Hideout" )
    , ( "藏身處 - 苦難之室", "Morbid Hideout" )
    , ( "藏身處 - 長草花園", "Overgrown Hideout" )
    , ( "藏身處 - 貪婪之盡", "Ravenous Hideout" )
    , ( "藏身處 - 盜匪壕溝", "Robber's Trench Hideout" )
    , ( "藏身處 - 緋紅之殿", "Sanguine Hideout" )
    , ( "藏身處 - 塑形幻域", "Shaped Hideout" )
    , ( "藏身處 - 骸骨墓場", "Skeletal Hideout" )
    , ( "藏身處 - 莊嚴之室", "Stately Hideout" )
    , ( "藏身處 - 沉淪地域", "Sunken Hideout" )
    , ( "藏身處 - 烈陽之巔", "Sunspire Hideout" )
    , ( "藏身處 - 高塔", "Towering Hideout" )
    , ( "藏身處 - 地下城", "Undercity Hideout" )
    , ( "藏身處 - 考古場", "Unearthed Hideout" )

    -- fix #32 - I messed up the map name the first time. Easier to add an alias than change it everywhere.
    , ( "The Hall of Grandmasters", "Hall of Grandmasters" )
    ]
