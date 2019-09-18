const querystring = require('querystring')
const fs = require('fs')
const path = require('path')
const readline = require('readline')
const {Elm} = require('@mapwatch/www')
const Lib = require('@mapwatch/lib')
const _ = require('lodash/fp')
const {promisify} = require('util')
const analytics = require('@mapwatch/www/src/analytics.js')

const loadedAt = Date.now()
const qs = querystring.parse(document.location.search.slice(1))
const tickStart = qs.tickStart && new Date(Number.isNaN(parseInt(qs.tickStart)) ? qs.tickStart : parseInt(qs.tickStart))
const tickOffset = qs.tickOffset || tickStart ? loadedAt - tickStart.getTime() : 0
console.log('tickOffset', tickOffset, qs)
function toElmUrl(url) {
  return url.replace(/^file:\/\/\//, 'https://')
}
function fromElmUrl(url) {
  return url.replace(/^https:\/\//, 'file:///')
}
const app = Elm.Main.init({
  // node: document.documentElement,
  node: document.getElementById('root'),
  flags : {
    loadedAt,
    tickOffset: tickOffset,
    isBrowserSupported: !!window.FileReader,
    platform: 'electron',
    hostname: 'https://mapwatch.erosson.org',
    url: toElmUrl(location.href),
  }
})

// https://github.com/elm/browser/blob/1.0.0/notes/navigation-in-elements.md
window.addEventListener('popstate', function() {
  app.ports.onUrlChange.send(toElmUrl(location.href))
})
//app.ports.pushUrl.subscribe(function(url) {
//  history.pushState({}, '', url)
//  app.ports.onUrlChange.send(location.href)
//})
app.ports.replaceUrl.subscribe(function(url) {
  history.replaceState({}, '', fromElmUrl(url))
  app.ports.onUrlChange.send(toElmUrl(location.href))
})

analytics.main(app, 'electron')
fetch('./node_modules/@mapwatch/www/build/version.txt')
.then(function(res) { return res.text() })
.then(analytics.version)

fetch('./node_modules/@mapwatch/www/build/CHANGELOG.md')
.then(function(res) { return res.text() })
.then(function(str) {
  console.log('fetched changelog', str.length)
  app.ports.changelog.send(str)
})

function processFile(path_, historySize) {
  console.log('processfile', path_, historySize)
  const startedAt = Date.now()
  const watcher = new Lib.MapWatcher(app)
  watcher.watch(path_, {
    historySize,
    onHistoryOpen: size => {
      console.log('historyopen', size)
      app.ports.progress.send({name: 'history', val: 0, max: size, startedAt, updatedAt: Date.now()})
    },
    onOpen: size => {
      console.log('open', size)
      app.ports.progress.send({name: 'file', val: 0, max: size, startedAt, updatedAt: Date.now()})
    },
    onClose: (event, size) => {
      console.log('close', event, size)
      app.ports.progress.send({name: 'file', val: size, max: size, startedAt, updatedAt: Date.now()})
    },
  })
}

var MB = Math.pow(2, 20)
if (qs.clear) {
  window.localStorage.clear()
}
// load an example file
if (qs.example) {
  console.log("fetching example file: ", qs.example, qs)
  processFile(path.join(__dirname, './node_modules/@mapwatch/www/public/examples', qs.example), 999 * MB)
}
// try to automatically load the log path, with no user interaction. Might fail.
if (!qs.pathSelect) {
  const tryPaths = [
    qs.path,
    window.localStorage.getItem('mapwatch.path'),
    "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
    "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
  ].filter(_.identity)
  tryPaths.reduce((accum, path) => {
    return accum.catch(errs => {
      return new Promise((resolve, reject) =>
        promisify(fs.access)(path)
        .then(() => resolve(path))
        .catch(err => reject(errs && errs.concat ? errs.concat([path]) : errs || [path]))
      )
    })
  }, new Promise((resolve, reject) => reject([])))
  .then(path => {
    console.log("found a log path to autoload:", path)
    var maxSize = (qs.maxSize == null ? 20 : qs.maxSize) * MB
    processFile(path, maxSize)
  })
  .catch(err => console.warn("failed to autoload a log path", err))
}
// load a manually-selected log path
app.ports.inputClientLogWithId.subscribe(config => {
  var files = document.getElementById(config.id).files
  var maxSize = (config.maxSize == null ? (qs.maxSize == null ? 20 : qs.maxSize) : config.maxSize) * MB
  if (files.length > 0) {
    window.localStorage.setItem('mapwatch.path', files[0].path)
    processFile(files[0].path, maxSize)
  }
})
