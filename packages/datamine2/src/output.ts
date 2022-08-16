import {WorldArea, headers as wa_headers} from './worldarea'
import * as input from './input'
import {Lang} from './lang'

export interface Output {
    worldAreas: {
        header: string[]
        data: unknown[][]
    }
    lang: {[name: string]: Lang}
}

export function build(ws: WorldArea[], lang: {[name: string]: Lang}, i: input.Input): Output {
    const worldAreas = {
        header: wa_headers,
        data: ws.map(worldAreaToRow),
    }
    return {worldAreas, lang}
}

function worldAreaToRow(w: WorldArea): unknown[] {
    return wa_headers.map(h => w[h])
}
