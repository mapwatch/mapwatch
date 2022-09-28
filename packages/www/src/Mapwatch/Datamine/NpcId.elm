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
    -- not sirus, he behaves very differently from the others
    Set.fromList [ baran, veritania, alHezmin, drox ]


baran =
    "Metadata/Monsters/AtlasExiles/AtlasExile1"


veritania =
    "Metadata/Monsters/AtlasExiles/AtlasExile2"


alHezmin =
    "Metadata/Monsters/AtlasExiles/AtlasExile3"


drox =
    "Metadata/Monsters/AtlasExiles/AtlasExile4"


sirus =
    "Metadata/Monsters/AtlasExiles/AtlasExile5"


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


shaper =
    "Metadata/NPC/Shaper"



-- heist


karst =
    "Metadata/NPC/League/Heist/Lockpick1"


niles =
    "Metadata/NPC/League/Heist/Interrogator1"


huck =
    "Metadata/NPC/League/Heist/Soldier1"


tibbs =
    "Metadata/NPC/League/Heist/HeavyLifter1"


nenet =
    "Metadata/NPC/League/Heist/Detector1"


vinderi =
    "Metadata/NPC/League/Heist/Demolitionist1"


tortilla =
    -- https://www.reddit.com/r/pathofexile/comments/iwbvt2/got_it_good/
    "Metadata/NPC/League/Heist/CatBurglar1"


gianna =
    "Metadata/NPC/League/Heist/Illusionist1"


isla =
    "Metadata/NPC/League/Heist/Engineer1"


heistNpcsList =
    [ karst
    , niles
    , huck
    , tibbs
    , nenet
    , vinderi
    , tortilla
    , gianna
    , isla
    ]


heistNpcs =
    Set.fromList heistNpcsList



-- echoes


envoy =
    "Metadata/NPC/Epilogue/Envoy"


maven =
    "Metadata/NPC/Epilogue/Maven"


oshabi =
    "Metadata/NPC/League/Harvest/HarvestNPC"


trialmaster =
    "Metadata/NPC/League/Ultimatum/UltimatumNPC"


gwennen =
    "Metadata/NPC/League/Expedition/Gambler"


tujen =
    "Metadata/NPC/League/Expedition/Haggler"


rog =
    -- "Metadata/NPC/League/Expedition/Dealer"
    "Metadata/Monsters/LeagueExpedition/NPC/ExpeditionRog"


dannig =
    "Metadata/NPC/League/Expedition/Saga"



-- 3.17 siege of the atlas bosses


blackstar =
    "Metadata/Monsters/AtlasInvaders/BlackStarMonsters/BlackStarBoss"


exarch =
    "Metadata/Monsters/AtlasInvaders/CleansingMonsters/CleansingBoss"


eater =
    "Metadata/Monsters/AtlasInvaders/ConsumeMonsters/ConsumeBoss"


hunger =
    "Metadata/Monsters/AtlasInvaders/DoomMonsters/DoomBoss"
