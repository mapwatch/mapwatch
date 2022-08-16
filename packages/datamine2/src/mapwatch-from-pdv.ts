/**
 * After collecting raw pdv output, format it for use in mapwatch.
 */
import * as input from './input'
import * as worldarea from './worldarea'
import * as lang from './lang'
import * as output from './output'

async function main() {
    const i: input.Input = await input.load()
    const ws: worldarea.WorldArea[] = i.worldAreas.map(w => worldarea.build(w, i)).filter(worldarea.filter)
    const filteredWs: Set<string> = new Set(ws.map(w => w.Id))
    const ls: {[name: string]: lang.Lang} = Object.fromEntries(Object.entries(i.lang).map(([name, l]) => [name, lang.build(l, filteredWs)]))
    const o: output.Output = output.build(ws, ls, i)
    console.log(JSON.stringify(o, null, 2))
}
main().catch(err => {
    console.error(err)
    process.exit(1)
})