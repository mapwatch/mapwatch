import * as input from './input'
import { WorldArea } from './worldarea'

export interface Lang {
    backendErrors: { [key: string]: string }
    npcs: { [key: string]: string }
    npcTextAudio: { [key: string]: string }
    worldAreas: { [key: string]: string }
}

export function build(il: input.Lang, filteredWorldAreas: Set<string>): Lang {
    // areas all have different names for different languages, map id -> name.
    // mapwatch is usually more concerned with name -> id for log parsing, but it can deal.
    const worldAreas = Object.fromEntries(il.worldAreas
        .filter(w => filteredWorldAreas.has(w.Id))
        .map(a => [a.Id, a.Name])
    )
    // "You have entered" text can vary based on the user's language, so import it too
    const backendErrorIds = new Set(['EnteredArea', 'AFKModeEnabled', 'AFKModeDisabled', 'PlayerSlain', 'PlayerSuicide'])
    const backendErrors = Object.fromEntries(il.backendErrors
        .filter(e => backendErrorIds.has(e.Id))
        .map(a => [a.Id, a.Text])
    )
    const npcs = Object.fromEntries(il.npcs
        .filter(isNPCIdExported)
        .map(a => [a.Id, a.Name])
    )
    const npcTextAudio = Object.fromEntries(il.npcTextAudio
        .filter(isNPCTextExported)
        .map(a => [a.Id, a.Text])
    )
    return { backendErrors, npcs, npcTextAudio, worldAreas }
}
const exportedNPCs = new Set([
    // conquerors
    "Metadata/Monsters/AtlasExiles/AtlasExile1",
    "Metadata/Monsters/AtlasExiles/AtlasExile2",
    "Metadata/Monsters/AtlasExiles/AtlasExile3",
    "Metadata/Monsters/AtlasExiles/AtlasExile4",
    "Metadata/Monsters/AtlasExiles/AtlasExile5",
    // masters. no Zana dialogue, she's already tracked by detecting maps within maps
    "Metadata/Monsters/Masters/Einhar",
    "Metadata/Monsters/LeagueIncursion/Alva",
    "Metadata/NPC/League/Delve/DelveMiner",
    "Metadata/Monsters/LeagueBetrayal/MasterNinjaCop", // ninja-cop, lol
    "Metadata/Monsters/Masters/BlightBuilderWild",
    // other dialogue-based encounters
    "Metadata/NPC/League/Metamorphosis/MetamorphosisNPC",
    "Metadata/NPC/League/Affliction/StrangeVoice",
    "Metadata/Monsters/LegionLeague/LegionKaruiGeneral",
    "Metadata/Monsters/LegionLeague/LegionEternalEmpireGeneral",
    "Metadata/Monsters/LegionLeague/LegionMarakethGeneral",
    "Metadata/Monsters/LegionLeague/LegionMarakethGeneralDismounted",
    "Metadata/Monsters/LegionLeague/LegionTemplarGeneral",
    "Metadata/Monsters/LegionLeague/LegionVaalGeneral",
    "Metadata/NPC/Shaper",
    "Metadata/NPC/League/Harvest/HarvestNPC",
    "Metadata/NPC/Epilogue/Envoy",
    "Metadata/NPC/Epilogue/Maven",
    // the trialmaster
    "Metadata/NPC/League/Ultimatum/UltimatumNPC",
    "Metadata/NPC/League/Expedition/Gambler",
    "Metadata/NPC/League/Expedition/Haggler",
    // strangely, Rog's in-game messages don't have a title suffix the way damn near every other NPC in the game does.
    // "Rog", not "Rog, the Dealer". Worried that the short name will cause false positives, but let's see how it goes...
    // "Metadata/NPC/League/Expedition/Dealer",
    "Metadata/Monsters/LeagueExpedition/NPC/ExpeditionRog",
    "Metadata/NPC/League/Expedition/Saga",
    // high templar venarius (cortex)
    "Metadata/Monsters/LeagueSynthesis/SynthesisVenariusBoss",
    // 3.17: eater and exarch
    // black star
    "Metadata/Monsters/AtlasInvaders/BlackStarMonsters/BlackStarBoss",
    // exarch
    "Metadata/Monsters/AtlasInvaders/CleansingMonsters/CleansingBoss",
    // eater
    "Metadata/Monsters/AtlasInvaders/ConsumeMonsters/ConsumeBoss",
    // infinite hunger
    "Metadata/Monsters/AtlasInvaders/DoomMonsters/DoomBoss_",
])
function isNPCIdExported(i: input.NPC): boolean {
    return !!exportedNPCs.has(i.Id)
        || i.Id.startsWith("Metadata/Monsters/LeagueBetrayal/Betrayal")
        || i.Id.startsWith("Metadata/NPC/League/Heist/")
}
function isNPCTextExported(i: input.NPCTextAudio): boolean {
    // conquerors
    return /^AlHezmin.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(i.Id)
        || /^Veritania.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(i.Id)
        || /^Baran.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(i.Id)
        || /^Drox.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(i.Id)
        // masters
        // Turns out for most of these, we don't care what they have to say.
        // Saying anything at all is enough.
        // || /^EinharArrives/.test(raw.Id)
        // || /^AlvaWild/.test(raw.Id)
        // || /^NikoClaim/.test(raw.Id)
        // TODO: Jun and the syndicate are tricky. Their NPCText ids aren't named
        // after Jun, but after each syndicate member; I'll need to list them all.
        // /^<NAME>PrimaryDefenderStartsFight/ for all of them looks like it'd be enough.
        // Alternately, could ignore exact dialogue and just check the speaker?
        // || /^JunOrtoi/.test(raw.Id)
        // || /^BlightBuilderWildAttention/.test(raw.Id)
        // || /^TaneOctaviusWildGreeting|TaneOctaviusGreeting/.test(raw.Id)
        // We detect Blighted maps by counting 8 or more Cassia "it's branching"s
        || /^CassiaNewLane\d*$/.test(i.Id)
        // Shaper voicelines distinguish shaper-map vs. uber-elder-map, since they have the same zone name. https://github.com/mapwatch/mapwatch/issues/55
        || 'ShaperMapShapersRealm' === i.Id
        || 'ShaperUberElderIntro' === i.Id
        // Heist skill use voicelines. We rely on voicelines to distinguish
        // contracts from grand heists, and have to exclude all pre-mission
        // chatter in town. The names are wonderfully inconsistent.
        || /^Karst(LockPick|Perception|Vaultcracking)/.test(i.Id)
        || /^Niles(Thaumaturgy|Deception)/.test(i.Id)
        || /^Huck(Lockpicking|Bruteforce|Demolition)/.test(i.Id)
        || /^Tibbs(ForcingObstacle|Demolition)/.test(i.Id)
        || /^Nenet(Perception|Vault|Thaumaturgy)/.test(i.Id)
        || /^Vinderi(VaultBreaking|Engineering|DismantleTrap|Demolition)/.test(i.Id)
        || /^Tullina(Agility|DisarmTrap|TrapDisarm|Lockpick)/.test(i.Id)
        || /^Gianna(Perception|Deception|Smuggler|Cultist|Engineer)/.test(i.Id)
        || /^EngineeringGianna/.test(i.Id)
        || /^Isla(Engineering|DisarmTrap|CounterThaumaturgy)/.test(i.Id)
        // Oshabi: distinguish plain harvests vs. Heart of the Grove boss.
        // TODO: In 3.11, Oshabi disappears after beating heart of the grove,
        // silencing harvests in the logs. Is this still true in 3.13?
        || /^HarvestBoss/.test(i.Id)
        || /^HarvestReBoss/.test(i.Id)
        || /^OshabiWhenHarvesting/.test(i.Id)
        || /^OshabiWhenFightEnds/.test(i.Id)
        // Trialmaster: very specific voicelines, lots we can analyze
        || /^Trialmaster/.test(i.Id)
        // Exarch and eater
        || /^CleansingFireDefeated/.test(i.Id)
        || /^ConsumeBossDefeated/.test(i.Id)
        || /^DoomBossDefeated/.test(i.Id)
        || /^TheBlackStarDeath/.test(i.Id)
        // Other boss defeats:
        // the shaper
        || /^ShaperBanish/.test(i.Id)
        // cortex
        || 'VenariusBossFightDepart' === i.Id
        // maven
        || /^MavenFinalFightRealises/.test(i.Id)
        || /^MavenFinalFightApologi/.test(i.Id)
        || /^MavenFinalFightInvites/.test(i.Id)
        || /^MavenFinalFightRepeated/.test(i.Id)
        // elder (and other bosses) with maven
        || /^MavenTier5OffAtlas/.test(i.Id)
        || /^MavenTier5FirstOffAtlas/.test(i.Id)
        // sirus. Not sure the complex death lines are ever used, but it doesn't hurt
        || 'SirusSimpleDeathLine' === i.Id
        || /^SirusComplexDeathLine/.test(i.Id)
        // shaper guardians. "this is the key to a crucible..."
        || 'ShaperAtlasMapDrops' === i.Id
        // mastermind death check
        // || 'CatarinaDowned' === i.Id
        || /^JunOnKillingCatarina/.test(i.Id)
}