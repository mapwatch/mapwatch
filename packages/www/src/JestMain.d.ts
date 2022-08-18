// type definitions for a test are overkill, normally `any` would be enough.
// I'm just using this to learn how typescript definition files work.
// https://www.npmjs.com/package/@types/elm
import { ElmApp, ElmMain, PortFromElm, PortToElm } from 'elm'
export { PortFromElm, PortToElm } from 'elm'

export const Elm: {
    JestMain: {
        init(options: { node?: Node | undefined; flags?: any }): App
    }
}
export type App = {
    ports: Ports
}
export interface Ports {
    initCmd: PortFromElm<InitCmd>
    mapRunSub: PortToElm<MapRunSub>
    mapRunCmd: PortFromElm<MapRunCmd>
}

export interface InitCmd {
    status: string
    message: string | null
}
export interface MapRunSub {
    body: string
}
export interface MapRunCmd {
    status: string
    body: unknown[] | null
}