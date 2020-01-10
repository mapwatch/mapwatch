import '@fortawesome/fontawesome-free/css/all.css';
import 'sakura.css/css/sakura-vader.css';
import './main.css';
import {Elm} from './Main.elm';
import * as registerServiceWorker from './registerServiceWorker';
import * as analytics from './analytics'
import * as util from './util'
import * as logReader from './logReader'
import {BrowserBackend} from './browserBackend'
import {MemoryBackend} from './memoryBackend'
import {default as datamine} from '@mapwatch/datamine'
const MB = logReader.MB

// redirect from old host to new host.
// TODO this should really be a 301 redirect from the server!
// Quick-and-dirty version: js redirect + `link rel=canonical`
if (document.location.host === 'mapwatch.github.io') {
  document.location.host = 'mapwatch.erosson.org'
}

function main() {
  // The Electron preload script sets window.backend. This is the only way we
  // distinguish the Electron version from the browser version.
  const backend = window.backend || new BrowserBackend()

  const qs = util.parseQS(document.location.search)
  const flags = createFlags(backend, qs)
  const app = Elm.Main.init({flags})
  console.log('init', {backend, flags, datamine})

  // fetch external files for elm
  analytics.main(app, 'www')
  fetch('./version.txt')
  .then(function(res) { return res.text() })
  .then(analytics.version)

  fetch('./CHANGELOG.md')
  .then(function(res) { return res.text() })
  .then(function(str) {
    console.log('fetched changelog', str.length)
    app.ports.changelog.send(str)
  })

  app.ports.inputClientLogWithId.subscribe(config => {
    var files = document.getElementById(config.id).files
    var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
    if (files.length > 0) {
      console.log('files', files)
      backend.open(files[0], maxSize)
      .then(() => {
        logReader.processFile(app, backend, "history")
      })
    }
  })
  if (qs.example) {
    handleExample({app, flags, qs})
  }
  else {
    backend.autoOpen(20 * MB)
    .then(opened => {
      if (opened) {
        logReader.processFile(app, backend, "history")
      }
    })
  }

  const speechCapable = !!window.speechSynthesis && !!window.SpeechSynthesisUtterance
  // let sayWatching = true // useful for testing. uncomment me, upload a file, and i'll say all lines in that file
  let sayWatching = false
  let isSpeechEnabled = false
  let volume = 0
  app.ports.events.subscribe(function(event) {
    if (event.type === 'volume') {
      volume = event.volume
      isSpeechEnabled = event.isSpeechEnabled && speechCapable
      console.log('volume event', {volume, isSpeechEnabled, speechCapable})
    }
    if (event.type === 'progressComplete' && !sayWatching && (event.name === 'history' || event.name === 'history:example')) {
      sayWatching = true
      say({say: 'mapwatch now running.', volume: isSpeechEnabled ? volume : 0})
    }
    if (event.type === 'joinInstance' && sayWatching && event.say) {
      say({say: event.say, volume: isSpeechEnabled ? volume : 0})
    }
  })
}

function createFlags(backend, qs) {
  const loadedAt = Date.now()
  const tickStart = qs.tickStart && new Date(isNaN(parseInt(qs.tickStart)) ? qs.tickStart : parseInt(qs.tickStart))
  const tickOffset = qs.tickOffset || tickStart ? loadedAt - tickStart.getTime() : 0
  if (tickOffset) console.log('tickOffset set:', {tickOffset: tickOffset, tickStart: tickStart})
  return {
    loadedAt,
    tickOffset,
    isBrowserSupported: !!window.FileReader,
    // isBrowserSupported: false,
    platform: backend.platform,
    datamine,
  }
}
function handleExample({app, flags, qs}) {
  console.log("fetching example file: ", qs.example, qs)
  // show a progress spinner, even when we don't know the size yet
  var sendProgress = logReader.progressSender(app, flags.loadedAt, "history:example")(0, 0, flags.loadedAt)
  fetch("./examples/"+qs.example)
  .then(res => {
    if (res.status < 200 || res.status >= 300) {
      return Promise.reject("non-200 status: "+res.status)
    }
    return res.blob()
  })
  .then(blob => blob.text())
  .then(text => {
    logReader.processFile(app, MemoryBackend(text), "history:example")
  })
  .catch(function(err) {
    console.error("Error fetching example:", err)
  })
}

function say(args) {
  if (args.volume > 0) {
    // console.log(speechSynthesis.getVoices())
    var utterance = new SpeechSynthesisUtterance(args.say)
    utterance.volume = args.volume;
    speechSynthesis.speak(utterance)
  }
}

main()
