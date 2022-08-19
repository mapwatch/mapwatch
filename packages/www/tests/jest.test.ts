import * as Elm from '../tmp/JestMain'
import * as datamine from '../src/datamine'
import fs from 'fs/promises'

async function awaitCmd<V>(port: Elm.PortFromElm<V>, afterSub: CallableFunction=() => {}): Promise<V> {
    return new Promise<V>(resolve => {
        function handler(msg: V) {
            resolve(msg)
            port.unsubscribe(handler)
        }
        port.subscribe(handler)
        afterSub()
    })
}
async function init(): Promise<Elm.App> {
    const app = Elm.Elm.JestMain.init({flags: {datamine}})
    const res = await awaitCmd<Elm.InitCmd>(app.ports.initCmd)
    expect(res.status).toBe('ready')
    expect(res.message).toBeNull()
    return app
}

test('jest runs', () => {
    expect(1 + 1).toBe(2)
})
test('elm is imported', () => {
    expect(Elm.Elm).toBeDefined()
    expect(Elm.Elm.JestMain).toBeDefined()
    expect(Elm.Elm.JestMain.init).toBeDefined()
})

test('elm inits', async () => {
    const app = await init()
})

test('elm snapshots', async () => {
    const app = await init()
    const body = ""
    app.ports.mapRunSub.send({body})
    const res = await awaitCmd<Elm.MapRunCmd>(app.ports.mapRunCmd)
    expect(res.body).toBe("[]")
})

test('elm snapshot stripped-client', async () => {
    const app = await init()
    const body = (await fs.readFile('./public/examples/stripped-client.txt')).toString()
    const res = await awaitCmd<Elm.MapRunCmd>(app.ports.mapRunCmd, () => app.ports.mapRunSub.send({body}))
    expect(res.body).toMatchSnapshot()
})