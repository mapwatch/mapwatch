module Mapwatch.Datamine.NpcId exposing (..)

import Set exposing (Set)


type alias NpcId =
    String


conquerors =
    Set.fromList [ baran, veritania, alHezmin, drox ]


baran =
    "Metadata/Monsters/AtlasExiles/AtlasExile1"


veritania =
    "Metadata/Monsters/AtlasExiles/AtlasExile2"


alHezmin =
    "Metadata/Monsters/AtlasExiles/AtlasExile3"


drox =
    "Metadata/Monsters/AtlasExiles/AtlasExile4"


einhar =
    "Metadata/Monsters/Masters/Einhar"


alva =
    "Metadata/Monsters/LeagueIncursion/Alva"


niko =
    "Metadata/NPC/League/Delve/DelveMiner"


jun =
    "Metadata/Monsters/LeagueBetrayal/MasterNinjaCop"


cassia =
    "Metadata/Monsters/Masters/BlightBuilderWild"


tane =
    "Metadata/NPC/League/Metamorphosis/MetamorphosisNPC"
