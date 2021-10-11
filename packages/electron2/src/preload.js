const { contextBridge } = require('electron')
const args = require('minimist')(process.argv.slice(2))

console.log('preloading...', args.mapwatchElectronFlags)
if (!args.mapwatchElectronFlags) {
    throw new Error('electron requires --mapwatchElectronFlags')
}
contextBridge.exposeInMainWorld('backend', require('./electronBackend').ElectronBackend())
contextBridge.exposeInMainWorld('electronFlags', JSON.parse(args.mapwatchElectronFlags))
console.log('preloaded')
