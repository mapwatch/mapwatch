import * as fs from 'fs/promises'
import * as t from 'io-ts'
import * as F from 'fp-ts/function'
import * as A from 'fp-ts/Array'

export interface Input {
    atlasNodes: AtlasNode[]
    // backendErrors: BackendError[]
    itemVisualIdentity: ItemVisualIdentity[]
    // npcs: NPC[]
    // npcTextAudio: NPCTextAudio[]
    ultimatumModifiers: UltimatumModifier[]
    uniqueMaps: UniqueMap[]
    worldAreas: WorldArea[]
    mapIcons: MapIcon[]

    lang: { [name: string]: Lang }

    worldAreasById: { [key: string]: WorldArea }
    worldAreasByIndex: { [key: number]: WorldArea }
    atlasNodesByWorldArea: { [key: number]: AtlasNode }
    uniqueMapsByWorldArea: { [key: number]: UniqueMap }
    itemVisualIdentityByIndex: { [key: number]: ItemVisualIdentity }
    mapIconsByName: { [key: string]: MapIcon }
}

export interface Lang {
    backendErrors: BackendError[]
    npcs: NPC[]
    npcTextAudio: NPCTextAudio[]
    worldAreas: WorldAreaLang[]

    worldAreasById: { [id: string]: WorldAreaLang }
}

export const AtlasNode = t.type({
    WorldAreasKey: t.number,
    ItemVisualIdentityKey: t.number,
    Tier0: t.number,
    Tier1: t.number,
    Tier2: t.number,
    Tier3: t.number,
    Tier4: t.number,
    DDSFile: t.string,
})
export type AtlasNode = t.TypeOf<typeof AtlasNode>

export const MapIcon = t.type({
    name: t.string,
    icon: t.string,
})
export type MapIcon = t.TypeOf<typeof MapIcon>

export const BackendError = t.type({
    Id: t.string,
    Text: t.string,
})
export type BackendError = t.TypeOf<typeof BackendError>

export const ItemVisualIdentity = t.type({
    _index: t.number,
    Id: t.string,
    DDSFile: t.string,
})
export type ItemVisualIdentity = t.TypeOf<typeof ItemVisualIdentity>

export const NPC = t.type({
    Id: t.string,
    Name: t.string,
})
export type NPC = t.TypeOf<typeof NPC>

export const NPCTextAudio = t.type({
    Id: t.string,
    Text: t.string,
})
export type NPCTextAudio = t.TypeOf<typeof NPCTextAudio>

export const UltimatumModifier = t.type({
    Id: t.string,
    Name: t.string,
    Icon: t.string,
    Tier: t.number,
    Description: t.string,
})
export type UltimatumModifier = t.TypeOf<typeof UltimatumModifier>

export const UniqueMap = t.type({
    WorldAreasKey: t.number,
    ItemVisualIdentityKey: t.number,
})
export type UniqueMap = t.TypeOf<typeof UniqueMap>

export const WorldArea = t.type({
    _index: t.number,
    Id: t.string,
    IsTown: t.boolean,
    IsMapArea: t.boolean,
    IsHideout: t.boolean,
    IsVaalArea: t.boolean,
    IsUniqueMapArea: t.boolean,
})
export type WorldArea = t.TypeOf<typeof WorldArea>

export const WorldAreaLang = t.type({
    Id: t.string,
    Name: t.string,
})
export type WorldAreaLang = t.TypeOf<typeof WorldAreaLang>

const DATA_DIR = `${__dirname}/../build/data`
const DATA_MAIN = `${DATA_DIR}/main/tables/English`
const DATA_LANG = `${DATA_DIR}/lang/tables`
const DIST_DIR = `${__dirname}/../dist`

export async function load(): Promise<Input> {
    const [atlasNodes, itemVisualIdentity, ultimatumModifiers, uniqueMaps, worldAreas, mapIcons, lang] = await Promise.all([
        loadFile(`${DATA_MAIN}/AtlasNode.json`, AtlasNode),
        // loadFile(`${DATA_MAIN}/BackendErrors.json`, BackendError),
        loadFile(`${DATA_MAIN}/ItemVisualIdentity.json`, ItemVisualIdentity),
        // loadFile(`${DATA_MAIN}/NPCs.json`, NPC),
        // loadFile(`${DATA_MAIN}/NPCTextAudio.json`, NPCTextAudio),
        loadFile(`${DATA_MAIN}/UltimatumModifiers.json`, UltimatumModifier),
        loadFile(`${DATA_MAIN}/UniqueMaps.json`, UniqueMap),
        loadFile(`${DATA_MAIN}/WorldAreas.json`, WorldArea),
        loadFile(`${DIST_DIR}/poedb-map-icons.json`, MapIcon),
        (async () => {
            const langs = await fs.readdir(`${DATA_LANG}`)
            return Object.fromEntries(await Promise.all(langs.map(
                async name => [name, await loadLang(name)]
            )))
        })(),
    ])
    if (!('English' in lang)) throw new Error("English translation not found")
    const worldAreasById = Object.fromEntries(worldAreas.map(a => [a.Id, a]))
    const worldAreasByIndex = Object.fromEntries(worldAreas.map(a => [a._index, a]))
    const atlasNodesByWorldArea = Object.fromEntries(atlasNodes.map(a => [a.WorldAreasKey, a]))
    const uniqueMapsByWorldArea = Object.fromEntries(uniqueMaps.map(a => [a.WorldAreasKey, a]))
    const itemVisualIdentityByIndex = Object.fromEntries(itemVisualIdentity.map(a => [a._index, a]))
    const mapIconsByName = Object.fromEntries(mapIcons.map(a => [a.name, a]))
    return { atlasNodes, itemVisualIdentity, ultimatumModifiers, uniqueMaps, worldAreas, mapIcons, lang, worldAreasById, worldAreasByIndex, atlasNodesByWorldArea, uniqueMapsByWorldArea, itemVisualIdentityByIndex, mapIconsByName }
}

async function loadLang(lang: string): Promise<Lang> {
    const [backendErrors, npcs, npcTextAudio, worldAreas] = await Promise.all([
        loadFile(`${DATA_LANG}/${lang}/BackendErrors.json`, BackendError),
        loadFile(`${DATA_LANG}/${lang}/NPCs.json`, NPC),
        loadFile(`${DATA_LANG}/${lang}/NPCTextAudio.json`, NPCTextAudio),
        loadFile(`${DATA_LANG}/${lang}/WorldAreas.json`, WorldAreaLang),
    ])
    const worldAreasById = Object.fromEntries(worldAreas.map(w => [w.Id, w]))
    return { backendErrors, npcs, npcTextAudio, worldAreas, worldAreasById }
}

async function loadFile<A>(path: string, codec: t.Type<A>): Promise<A[]> {
    const body = await fs.readFile(path)
    const json = JSON.parse(body.toString())
    // https://stackoverflow.com/questions/68301926/io-ts-parse-array-of-eithers-validations
    const { left, right } = F.pipe(
        json,
        A.map(codec.decode),
        A.separate,
    )
    if (left.length) {
        console.error(left)
        throw new Error(`failed to parse ${path}: ${left[0]}`)
    }
    return right
}