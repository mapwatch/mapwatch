module Mapwatch.Datamine.NpcId exposing (..)

import Set exposing (Set)


type alias NpcId =
    String


type alias NpcGroup =
    String


toNpcGroup : NpcId -> NpcGroup
toNpcGroup id =
    if Set.member id legionGenerals then
        legionGeneralGroup

    else if id == jun || String.startsWith "Metadata/Monsters/LeagueBetrayal/Betrayal" id then
        betrayalGroup

    else
        id


legionGeneralGroup =
    "__mapwatch:legion-general__"


betrayalGroup =
    "__mapwatch:betrayal__"


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


delirium =
    "Metadata/NPC/League/Affliction/StrangeVoice"


legionGenerals =
    Set.fromList
        [ "Metadata/Monsters/LegionLeague/LegionKaruiGeneral"
        , "Metadata/Monsters/LegionLeague/LegionEternalEmpireGeneral"
        , "Metadata/Monsters/LegionLeague/LegionMarakethGeneral"
        , "Metadata/Monsters/LegionLeague/LegionMarakethGeneralDismounted"
        , "Metadata/Monsters/LegionLeague/LegionTemplarGeneral"
        , "Metadata/Monsters/LegionLeague/LegionVaalGeneral"
        ]
