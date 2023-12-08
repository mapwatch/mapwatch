import * as input from './input'

export interface WorldArea {
    Id: string
    IsTown: boolean
    IsHideout: boolean
    IsMapArea: boolean
    IsUniqueMapArea: boolean
    IsVaalArea: boolean
    _IsLabTrial: boolean
    _IsLabyrinth: boolean
    _IsAbyssalDepths: boolean
    ItemVisualIdentity: string | null
    _PoedbMapIcon: string | null
    Tiers: null | [number, number, number, number, number]
}
export const headers: (keyof WorldArea)[] = [
    "Id",
    "IsTown",
    "IsHideout",
    "IsMapArea",
    "IsUniqueMapArea",
    "IsVaalArea",
    "_IsLabTrial",
    "_IsLabyrinth",
    "_IsAbyssalDepths",
    "ItemVisualIdentity",
    "Tiers",
    "_PoedbMapIcon"
]

export function filter(w: WorldArea): boolean {
    // I'm interested in maps, towns, and hideouts. other zones - usually campaign stuff - don't matter to mapwatch
    const criteria = w.IsMapArea
        || w.IsUniqueMapArea
        || w.IsTown
        || w.IsHideout
        || w.IsVaalArea
        || w._IsLabTrial
        || w._IsAbyssalDepths
        // include heist maps. The Twins zone name is "Mansion", but it's expressed
        // in these files as "The Den", which conflicts with the campaign zone, so exclude it.
        // https://github.com/mapwatch/mapwatch/issues/119
        || (w.Id.startsWith('Heist') && w.Id !== 'HeistBoss_Twins' && w.Id !== 'HeistHubEndless')
        || !!nonAtlasMaps[w.Id]
        || w.Id.includes("_Labyrinth_")
    // it looks like maps with no visuals are either duplicates or boss arenas. Either way, not interested
    const vis = w.ItemVisualIdentity || !w.IsMapArea
    return !!(criteria && vis)
}
export function build(w: input.WorldArea, i: input.Input): WorldArea {
    const a = i.atlasNodesByWorldArea[w._index]
    // a sanity check to make sure expected maps are imported. adjust as ggg rotates maps across leagues
    if (w.Id == 'MapWorldsGrotto' && !a) throw new Error('grotto should be on the atlas')
    // if (w.Id == 'MapWorldsBeach' && !a) throw new Error('beach should be on the atlas')
    const u = i.uniqueMapsByWorldArea[w._index]
    const _IsLabTrial = w.Id.startsWith('EndGame_Labyrinth_trials_')
    const _IsLabyrinth = w.Id.includes('_Labyrinth_') && !w.Id.includes("_Labyrinth_Airlock") && !_IsLabTrial
    const _IsAbyssalDepths = w.Id.startsWith('AbyssLeague')
    const Tiers: null | [number, number, number, number, number] = a ? [a.Tier0, a.Tier1, a.Tier2, a.Tier3, a.Tier4] : null

    const name: string = i.lang['English'].worldAreasById[w.Id].Name
    const _PoedbMapIcon: null | string = (i.mapIconsByName[name] || i.mapIconsByName[`${name} Map`])?.icon
    const ItemVisualIdentity = nonAtlasMapIcon(w)
        || i.itemVisualIdentityByIndex[u?.ItemVisualIdentityKey]?.DDSFile
        || i.itemVisualIdentityByIndex[a?.ItemVisualIdentityKey]?.DDSFile
        || (w.Id.startsWith('MapWorlds') ? i.itemVisualIdentityByIndex[w._index]?.DDSFile : null)
    return { ...w, _IsLabTrial, _IsLabyrinth, _IsAbyssalDepths, Tiers, ItemVisualIdentity, _PoedbMapIcon }
}
// Fragment maps, league boss areas, and Sirus don't seem to have a flag to
// easily distinguish them, nor do they have a field that says how to visualize.
// List them manually.
const nonAtlasMaps: { [name: string]: string } = {
    "3_ProphecyBoss": "Art/2DItems/Maps/PaleCourtComplete.png",
    "MapWorldsShapersRealm": "Art/2DItems/Maps/ShaperComplete.png",
    "MapWorldsElderArena": "Art/2DItems/Maps/ElderComplete.png",
    "MapWorldsElderArenaUber": "Art/2DItems/Maps/UberElderComplete.png",
    "MapAtziri1": "Art/2DItems/Maps/VaalComplete.png",
    "MapAtziri2": "Art/2DItems/Maps/UberVaalComplete.png",
    // sirus
    "AtlasExilesBoss5": "Art/2DItems/Currency/Strongholds/WatchstoneIridescent.png",
    // breachstones
    "BreachBossFire": "Art/2DItems/Currency/Breach/BreachFragmentsFire.png",
    "BreachBossCold": "Art/2DItems/Currency/Breach/BreachFragmentsCold.png",
    "BreachBossLightning": "Art/2DItems/Currency/Breach/BreachFragmentsLightning.png",
    "BreachBossPhysical": "Art/2DItems/Currency/Breach/BreachFragmentsPhysical.png",
    "BreachBossChaos": "Art/2DItems/Currency/Breach/BreachFragmentsChaos.png",
    // domain of timeless conflict
    "LegionLeague": "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLegion.png",
    "BetrayalMastermindFight": "Art/2DItems/Hideout/HideoutImageofCatarina.png",
    // These four are all named "Syndicate Hideout" so we can't tell them apart, but grouping them all should be fine
    "BetrayalSafeHouseFortress": "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png",
    "BetrayalSafeHouseAssassins": "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png",
    "BetrayalSafeHouseCaravan": "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png",
    "BetrayalSafeHouseLaboratory": "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png",
    // maven
    // "MavenHub": "Art/2DItems/Effects/Portals/MavenPortalEffect.png",
    "MavenHub": "Art/2DItems/Currency/AtlasRadiusTier4.png",
    "MavenBoss": "Art/2DItems/Currency/AtlasRadiusTier4.png",
    // 3.14
    "HarvestLeagueBoss": "Art/2DItems/Maps/OshabiMap.png",
    "UltimatumArena": "Art/2DItems/Maps/UltimatumTrialBase.png",
    "UltimatumArenaEndgame": "Art/2DItems/Maps/UltimatumTrialBase.png",
    "UltimatumBossArena": "Art/2DItems/Maps/UltimatumTrialBase.png",
    // 3.17: exarch and eater
    // infinite hunger
    "MapWorldsPrimordialBoss1": "https://web.poecdn.com/protected/image/item/popup/tangled-symbol.png?key=b-SVlhPy2jy-UJSTBaV2Cw",
    // black star
    "MapWorldsPrimordialBoss2": "https://web.poecdn.com/protected/image/item/popup/searing-symbol.png?key=iiOWJvWHj8-0bH0e28X7Xw",
    // exarch
    "MapWorldsPrimordialBoss3": "https://web.poecdn.com/protected/image/item/popup/searing-symbol.png?key=iiOWJvWHj8-0bH0e28X7Xw",
    // eater
    "MapWorldsPrimordialBoss4": "https://web.poecdn.com/protected/image/item/popup/tangled-symbol.png?key=b-SVlhPy2jy-UJSTBaV2Cw",
}
function nonAtlasMapIcon(w: input.WorldArea): string | null {
    if (w.Id in nonAtlasMaps) {
        return nonAtlasMaps[w.Id]
    }
    // delirium sanitarium - ids are AfflictionTown[1-10]
    if (w.Id.startsWith("AfflictionTown")) {
        return "Art/2DItems/Maps/DeliriumFragment.png"
    }
    // incursion temple - ids are Incursion_Temple[1-10],
    // sometimes with a trailing underscore just to mess us up.
    // No idea why it needs multiple ids, but it makes no difference
    if (w.Id.startsWith("Incursion_Temple")) {
        // return "Art/2DItems/Effects/Portals/IncursionPortal.png"
        return "Art/2DItems/Maps/TempleMap.png"
    }
    // Heist contracts. I can't find a way to associate heist zones to their item icon, so we'll do it by hand
    if (w.Id.startsWith("HeistBunker")) {
        return "Art/2DItems/Currency/Heist/ContractItem.png"
    }
    if (w.Id.startsWith("HeistMines")) {
        return "Art/2DItems/Currency/Heist/ContractItem2.png"
    }
    if (w.Id.startsWith("HeistDungeon")) {
        return "Art/2DItems/Currency/Heist/ContractItem3.png"
    }
    if (w.Id.startsWith("HeistReliquary")) {
        return "Art/2DItems/Currency/Heist/ContractItem4.png"
    }
    if (w.Id.startsWith("HeistLibrary")) {
        return "Art/2DItems/Currency/Heist/ContractItem5.png"
    }
    if (w.Id.startsWith("HeistRobotTunnels")) {
        return "Art/2DItems/Currency/Heist/ContractItem6.png"
    }
    if (w.Id.startsWith("HeistSewers")) {
        return "Art/2DItems/Currency/Heist/ContractItem7.png"
    }
    if (w.Id.startsWith("HeistCourts")) {
        return "Art/2DItems/Currency/Heist/ContractItem8.png"
    }
    if (w.Id.startsWith("HeistMansion")) {
        return "Art/2DItems/Currency/Heist/ContractItem9.png"
    }
    if (w.Id === "HeistBoss_AdmiralDarnaw") {
        return "Art/2DItems/Currency/Heist/AdmiralDarnawFightContract.dds"
    }
    if (w.Id === "HeistBoss_FreidrichTarollo") {
        // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
        return "Art/2DItems/Currency/Heist/SlaveMerchantFightContract.dds"
    }
    if (w.Id === "HeistBoss_Jamanra") {
        return "Art/2DItems/Currency/Heist/JamanraFightContract.dds"
    }
    if (w.Id === "HeistBoss_Nashta") {
        // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
        return "Art/2DItems/Currency/Heist/UsurperFightContract.dds"
    }
    if (w.Id === "HeistBoss_Twins") {
        // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
        return "Art/2DItems/Currency/Heist/VoxFamilyFightContract.dds"
    }
    if (w.Id === "HeistBoss_TheUnbreakable") {
        return "Art/2DItems/Currency/Heist/UnbreakableFightContract.dds"
    }
    return null
}
