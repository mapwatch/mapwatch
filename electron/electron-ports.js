const querystring = require('querystring')
const fs = require('fs')
const path = require('path')
const readline = require('readline')
const Elm = require('../dist/www/elm')

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
function readFile(path_, startedAt, start, size) {
  console.log('readfile', path_, startedAt, start, size)
  const reader = readline.createInterface({input: fs.createReadStream(path_, {start})})
  reader.on('line', line => {
    // console.log('line', line)
    app.ports.logline.send(line)
  })
  reader.on('close', line => {
    app.ports.progress.send({val: size, max: size, startedAt: startedAt, updatedAt: Date.now()})
  })
}
function processFile(path_, maxSize) {
  const startedAt = Date.now()
  fs.stat(path_, (err, stats) => {
    console.log('stats', stats)
    app.ports.progress.send({val: 0, max: stats.size, startedAt: startedAt, updatedAt: startedAt})
    // TODO real error handling
    if (err) return console.error(err)
    readFile(path_, startedAt, Math.max(0, maxSize ? stats.size - maxSize : 0), stats.size)

    let lastSize = stats.size
    let watcher = fs.watch(path_, () => {
      fs.stat(path_, (err, stats) => {
        // TODO real error handling
        if (err) return console.error(err)
        if (stats.size > lastSize) {
          readFile(path_, startedAt, lastSize, stats.size - lastSize)
        }
        lastSize = stats.size
      })
    })
  })
}
if (qs.example) {
  console.log("fetching example file: ", qs.example, qs)
  processFile(path.join(__dirname, '../assets/examples', qs.example))
}
var MB = Math.pow(2,20)
app.ports.inputClientLogWithId.subscribe(config => {
  var files = document.getElementById(config.id).files
  var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
  if (files.length > 0) {
    processFile(files[0].path, maxSize)
  }
})
