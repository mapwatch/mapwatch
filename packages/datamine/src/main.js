#!/usr/bin/env node
/** Preprocess PyPoE's json for Mapwatch's needs. */
const _ = require('lodash')
const schema = require('./schema/main.json')
const fs = require('fs').promises

fs.readdir('./dist/lang')
.catch(err => {
  console.error(err)
  process.exit(1)
})
.then(files => {
  const json = require('../dist/all.json')
  const lang = {}
  for (let file of files) {
    const key = file.replace('.json', '')
    lang[key] = require('../dist/lang/'+file)
  }
  main(json, lang)
})

function main(json, lang) {
  const out = transform(json, lang)
  console.log(JSON.stringify(out, null, 2))
  // console.log(JSON.stringify(out))
}
function transform(rawJson, rawLangs) {
  const json = _.keyBy(rawJson.map(file => {
    const header = file.header.map(h => h.name)
    const data = rowsToObjects(header, file.data)
    return {...file, header, data}
  }), 'filename')
  const langs = _.mapValues(rawLangs,
    l => _.keyBy(l.map(file => {
      const header = file.header.map(h => h.name)
      const data = rowsToObjects(header, file.data)
      return {...file, header, data}
    }), 'filename')
  )
  const uniqueMaps = json["UniqueMaps.dat"].data.map(n => transformUniqueMap(n, {json}))
  const atlasNodes = json["AtlasNode.dat"].data.map(n => transformAtlasNode(n, {json}))
  const worldAreas = json["WorldAreas.dat"].data.map((w, index) => transformWorldArea(w, {
    index,
    json,
    atlasNodes: _.keyBy(atlasNodes, 'WorldAreasKey'),
    uniqueMaps: _.keyBy(uniqueMaps, 'WorldAreasKey'),
    itemVisualIdentity: _.keyBy(json["ItemVisualIdentity.dat"].data, 'Id')
  }))
  // I'm interested in maps, towns, and hideouts. other zones - usually campaign stuff - don't matter to mapwatch
  .filter(w => w.IsMapArea
    || w.IsUniqueMapArea
    || w.IsTown
    || w.IsHideout
    || w.IsVaalArea
    || w._IsLabTrial
    || w._IsAbyssalDepths
    // include heist maps. The Twins zone name is "Mansion", but it's expressed
    // in these files as "The Den", which conflicts with the campaign zone, so exclude it.
    // https://github.com/mapwatch/mapwatch/issues/119
    || (w.Id.startsWith('Heist') && w.Id !== 'HeistBoss_Twins')
    || !!nonAtlasMaps[w.Id]
    || w.Id.includes("_Labyrinth_")
  )
  // it looks like maps with no visuals are either duplicates or boss arenas. Either way, not interested
  .filter(w => w.ItemVisualIdentity || !w.IsMapArea)

  const ret = _.mapValues({
    worldAreas,
  }, sheetFromObjects)
  ret.lang = _.mapValues(langs, l => transformLang(l, {json, worldAreasById: _.keyBy(worldAreas, 'Id')}))
  return ret
  // }, _.identity)
}
// Fragment maps, league boss areas, and Sirus don't seem to have a flag to
// easily distinguish them, nor do they have a field that says how to visualize.
// List them manually.
const nonAtlasMaps = {
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
  "MavenHub": "Art/2DItems/Effects/Portals/MavenPortalEffect.png",
  // 3.14
  "HarvestLeagueBoss": "Art/2DItems/Maps/OshabiMap.png",
  "UltimatumArena": "Art/2DItems/Maps/UltimatumTrialBase.png",
  "UltimatumArenaEndgame": "Art/2DItems/Maps/UltimatumTrialBase.png",
  "UltimatumBossArena": "Art/2DItems/Maps/UltimatumTrialBase.png",
}
function nonAtlasMapIcon(id) {
  if (nonAtlasMaps[id]) {
    return nonAtlasMaps[id]
  }
  // delirium sanitarium - ids are AfflictionTown[1-10]
  if (id.startsWith("AfflictionTown")) {
    return "Art/2DItems/Maps/DeliriumFragment.png"
  }
  // incursion temple - ids are Incursion_Temple[1-10],
  // sometimes with a trailing underscore just to mess us up.
  // No idea why it needs multiple ids, but it makes no difference
  if (id.startsWith("Incursion_Temple")) {
    return "Art/2DItems/Effects/Portals/IncursionPortal.png"
  }
  // Heist contracts. I can't find a way to associate heist zones to their item icon, so we'll do it by hand
  if (id.startsWith("HeistBunker")) {
    return "Art/2DItems/Currency/Heist/ContractItem.png"
  }
  if (id.startsWith("HeistMines")) {
    return "Art/2DItems/Currency/Heist/ContractItem2.png"
  }
  if (id.startsWith("HeistDungeon")) {
    return "Art/2DItems/Currency/Heist/ContractItem3.png"
  }
  if (id.startsWith("HeistReliquary")) {
    return "Art/2DItems/Currency/Heist/ContractItem4.png"
  }
  if (id.startsWith("HeistLibrary")) {
    return "Art/2DItems/Currency/Heist/ContractItem5.png"
  }
  if (id.startsWith("HeistRobotTunnels")) {
    return "Art/2DItems/Currency/Heist/ContractItem6.png"
  }
  if (id.startsWith("HeistSewers")) {
    return "Art/2DItems/Currency/Heist/ContractItem7.png"
  }
  if (id.startsWith("HeistCourts")) {
    return "Art/2DItems/Currency/Heist/ContractItem8.png"
  }
  if (id.startsWith("HeistMansion")) {
    return "Art/2DItems/Currency/Heist/ContractItem9.png"
  }
  if (id === "HeistBoss_AdmiralDarnaw") {
    return "Art/2DItems/Currency/Heist/AdmiralDarnawFightContract.dds"
  }
  if (id === "HeistBoss_FreidrichTarollo") {
    // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
    return "Art/2DItems/Currency/Heist/SlaveMerchantFightContract.dds"
  }
  if (id === "HeistBoss_Jamanra") {
    return "Art/2DItems/Currency/Heist/JamanraFightContract.dds"
  }
  if (id === "HeistBoss_Nashta") {
    // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
    return "Art/2DItems/Currency/Heist/UsurperFightContract.dds"
  }
  if (id === "HeistBoss_Twins") {
    // TODO is this icon right? It's a guess, could be mixed up with another heist boss with this comment
    return "Art/2DItems/Currency/Heist/VoxFamilyFightContract.dds"
  }
  if (id === "HeistBoss_TheUnbreakable") {
    return "Art/2DItems/Currency/Heist/UnbreakableFightContract.dds"
  }
  return null
}
function transformLang(raw, {worldAreasById}) {
  // areas all have different names for different languages, map id -> name.
  // mapwatch is usually more concerned with name -> id for log parsing, but it can deal.
  const worldAreas = raw["WorldAreas.dat"].data.filter(w => !!worldAreasById[w.Id])
  // "You have entered" text can vary based on the user's language, so import it too
  const backendErrors = raw["BackendErrors.dat"].data.filter(e => e.Id == 'EnteredArea')
  const npcs = raw["NPCs.dat"].data.filter(isNPCIdExported)
  const npcTextAudio = raw["NPCTextAudio.dat"].data.filter(isNPCTextExported)
  return {
    backendErrors: _.mapValues(_.keyBy(backendErrors, 'Id'), 'Text'),
    worldAreas: _.mapValues(_.keyBy(worldAreas, 'Id'), 'Name'),
    npcs: _.mapValues(_.keyBy(npcs, 'Id'), 'Name'),
    npcTextAudio: _.mapValues(_.keyBy(npcTextAudio, 'Id'), 'Text'),
  }
}
const exportedNPCs = Object.assign({}, ...[
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
].map(name => ({[name]: true})))
function isNPCIdExported(raw) {
  return !!exportedNPCs[raw.Id]
      || raw.Id.startsWith("Metadata/Monsters/LeagueBetrayal/Betrayal")
      || raw.Id.startsWith("Metadata/NPC/League/Heist/")
}
function isNPCTextExported(raw) {
  // conquerors
  return /^AlHezmin.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(raw.Id)
      || /^Veritania.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(raw.Id)
      || /^Baran.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(raw.Id)
      || /^Drox.*(Encounter|Fleeing|Fight|Death|ResponseToSirus)/.test(raw.Id)
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
      || /^CassiaNewLane\d*$/.test(raw.Id)
      // Shaper voicelines distinguish shaper-map vs. uber-elder-map, since they have the same zone name. https://github.com/mapwatch/mapwatch/issues/55
      || 'ShaperMapShapersRealm' === raw.Id
      || 'ShaperUberElderIntro' === raw.Id
      // Heist skill use voicelines. We rely on voicelines to distinguish
      // contracts from grand heists, and have to exclude all pre-mission
      // chatter in town. The names are wonderfully inconsistent.
      || /^Karst(LockPick|Perception|Vaultcracking)/.test(raw.Id)
      || /^Niles(Thaumaturgy|Deception)/.test(raw.Id)
      || /^Huck(Lockpicking|Bruteforce|Demolition)/.test(raw.Id)
      || /^Tibbs(ForcingObstacle|Demolition)/.test(raw.Id)
      || /^Nenet(Perception|Vault|Thaumaturgy)/.test(raw.Id)
      || /^Vinderi(VaultBreaking|Engineering|DismantleTrap|Demolition)/.test(raw.Id)
      || /^Tullina(Agility|DisarmTrap|TrapDisarm|Lockpick)/.test(raw.Id)
      || /^Gianna(Perception|Deception|Smuggler|Cultist|Engineer)/.test(raw.Id)
      || /^EngineeringGianna/.test(raw.Id)
      || /^Isla(Engineering|DisarmTrap|CounterThaumaturgy)/.test(raw.Id)
      // Oshabi: distinguish plain harvests vs. Heart of the Grove boss.
      // TODO: In 3.11, Oshabi disappears after beating heart of the grove,
      // silencing harvests in the logs. Is this still true in 3.13?
      || /^HarvestBoss/.test(raw.Id)
      || /^HarvestReBoss/.test(raw.Id)
      || /^OshabiWhenHarvesting/.test(raw.Id)
      || /^OshabiWhenFightEnds/.test(raw.Id)
      // Trialmaster: very specific voicelines, lots we can analyze
      || /^Trialmaster/.test(raw.Id)
}
function transformAtlasNode(raw, {json}) {
  return {
    WorldAreasKey: truthy(raw.WorldAreasKey, 'atlas.worldAreasKey'),
    ItemVisualIdentity: truthy(json["ItemVisualIdentity.dat"].data[raw.ItemVisualIdentityKey].DDSFile, raw),
    // DDSFile: truthy(raw.DDSFile, 'atlas.ddsfile'),
    AtlasRegion: truthy(json["AtlasRegions.dat"].data[raw.AtlasRegionsKey].Name, raw),
    Tiers: [raw.Tier0, raw.Tier1, raw.Tier2, raw.Tier3, raw.Tier4],
  }
}
function transformUniqueMap(raw, {json}) {
  return {
    WorldAreasKey: truthy(raw.WorldAreasKey, 'uniquemap.worldAreaskey'),
    ItemVisualIdentity: truthy(json["ItemVisualIdentity.dat"].data[raw.ItemVisualIdentityKey].DDSFile, raw),
  }
}
function transformWorldArea(raw, {index, json, uniqueMaps, atlasNodes, itemVisualIdentity}) {
  const _IsLabTrial = raw.Id.startsWith('EndGame_Labyrinth_trials_')
  return {
    Id: raw.Id,
    IsTown: raw.IsTown,
    IsHideout: raw.IsHideout,
    IsMapArea: raw.IsMapArea,
    IsUniqueMapArea: raw.IsUniqueMapArea,
    IsVaalArea: raw.IsVaalArea,
    _IsLabTrial,
    _IsLabyrinth: raw.Id.includes('_Labyrinth_') && !raw.Id.includes("_Labyrinth_Airlock") && !_IsLabTrial,
    _IsAbyssalDepths : raw.Id.startsWith('AbyssLeague'),
    ItemVisualIdentity: nonAtlasMapIcon(raw.Id) ||
      _.get(uniqueMaps[index] || atlasNodes[index], 'ItemVisualIdentity') ||
      (raw.Id.startsWith('MapWorlds') ? _.get(itemVisualIdentity[raw.Id], 'DDSFile') : null),
    AtlasRegion: _.get(atlasNodes[index], 'AtlasRegion'),
    Tiers: _.get(atlasNodes[index], 'Tiers'),
    RowID: index,
  }
}
function truthy(val, err) {
  if (!!val) return val
  // console.error(err)
  throw new Error("not truthy: "+err)
}
function rowsToObjects(header, rows) {
  return rows.map(r => _.zipObject(header, r))
}
function rowsFromObjects(header, rows) {
  return rows.map(r => header.map(k => r[k]))
}
function sheetFromObjects(rows) {
  const header = Object.keys(rows[0])
  return {
    header,
    data: rows.map(r => header.map(k => r[k]))
  }
}
