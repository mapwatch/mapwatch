const { contextBridge } = require('electron')

contextBridge.exposeInMainWorld('backend', require('./electronBackend').ElectronBackend())
contextBridge.exposeInMainWorld('electronFlags', JSON.parse(window.process.argv.slice(-1)[0]))
console.log('preloaded')
