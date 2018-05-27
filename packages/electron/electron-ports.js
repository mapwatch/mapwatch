const querystring = require('querystring')
const fs = require('fs')
const path = require('path')
const readline = require('readline')
const Elm = require('@mapwatch/www')
const Lib = require('@mapwatch/lib')

const loadedAt = Date.now()
const qs = querystring.parse(document.location.search.slice(1))
const tickStart = qs.tickStart && new Date(Number.isNaN(parseInt(qs.tickStart)) ? qs.tickStart : parseInt(qs.tickStart))
const tickOffset = qs.tickOffset || tickStart ? loadedAt - tickStart.getTime() : 0
console.log('tickOffset', tickOffset, qs)
const app = Elm.Main.fullscreen({
  loadedAt,
  tickOffset: tickOffset,
  isBrowserSupported: !!window.FileReader,
  platform: 'electron',
})

function processFile(path_, historySize) {
  console.log('processfile', path_, historySize)
  const startedAt = Date.now()
  const watcher = new Lib.MapWatcher(app)
  watcher.watch(path_, {
    historySize,
    onHistoryOpen: size => {
      console.log('historyopen', size)
      app.ports.progress.send({val: 0, max: size, startedAt, updatedAt: Date.now()})
    },
    onOpen: size => {
      console.log('open', size)
      app.ports.progress.send({val: 0, max: size, startedAt, updatedAt: Date.now()})
    },
    onClose: (event, size) => {
      console.log('close', event, size)
      app.ports.progress.send({val: size, max: size, startedAt, updatedAt: Date.now()})
    },
  })
}

var MB = Math.pow(2, 20)
if (qs.example) {
  console.log("fetching example file: ", qs.example, qs)
  processFile(path.join(__dirname, './node_modules/@mapwatch/www/assets/examples', qs.example), 999 * MB)
}
app.ports.inputClientLogWithId.subscribe(config => {
  var files = document.getElementById(config.id).files
  var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
  if (files.length > 0) {
    processFile(files[0].path, maxSize)
  }
})
