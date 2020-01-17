import '@fortawesome/fontawesome-free/css/all.css';
import 'sakura.css/css/sakura-vader.css';
import './main.css';
import {Elm} from './Main.elm';
import * as registerServiceWorker from './registerServiceWorker';
import * as analytics from './analytics'
import * as util from './util'
import {BrowserBackend} from './browserBackend'
import {MemoryBackend} from './memoryBackend'
import {default as datamine} from '@mapwatch/datamine'
import changelog from '!!raw-loader!../../../CHANGELOG.md'
// version.txt is created by by `yarn _build:version`
import version from '!!raw-loader!../tmp/version.txt'
// file-loader copies things into the website's static files; for example,
// this makes https://erosson.mapwatch.org/CHANGELOG.md work. Sort of like how
// `cp ... ./build/` in `yarn build` might work, but this also works in dev.
import '!!file-loader?name=CHANGELOG.md!../../../CHANGELOG.md'
import '!!file-loader?name=rss.xml!../../rss/dist/rss.xml'
import '!!file-loader?name=version.txt!../tmp/version.txt'

// Be careful with timezones throughout this file. Use Date.now(), not new Date(),
// for data sent to Elm: no risk of getting timezones involved that way.

const SETTINGS_KEY = 'mapwatch'
const MB = Math.pow(2,20)

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
  const settings = new Settings(SETTINGS_KEY, window.localStorage)
  const flags = createFlags({backend, settings, qs})
  const app = Elm.Main.init({flags})
  console.log('init', {backend, flags, datamine})

  analytics.main(app, backend.platform, version)

  let activeBackend = backend
  if (qs.example) {
    fetchExample(qs)
    .then(text => {
      // logReader.processFile(app, MemoryBackend(text), "history:example")
      activeBackend = MemoryBackend(text)
      console.log('example', activeBackend)
      app.ports.logOpened.send({date: Date.now(), size: activeBackend.size()})
    })
  }
  else {
    backend.autoOpen(20 * MB)
    .then(opened => {
      if (opened) {
        // logReader.processFile(app, backend, "history")
        app.ports.logOpened.send({date: Date.now(), size: backend.size()})
      }
    })
  }
  app.ports.logSelected.subscribe(config => {
    var files = document.getElementById(config.id).files
    var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
    if (files.length > 0) {
      console.log('files', files)
      activeBackend = backend
      backend.open(files[0], maxSize)
      .then(() => {
        // logReader.processFile(app, backend, "history")
        app.ports.logOpened.send({date: Date.now(), size: backend.size()})
      })
    }
  })
  app.ports.logSliceReq.subscribe(({position, length}) => {
    // console.log('logSliceReq', activeBackend)
    activeBackend.slice(position, length)
    .then(value => app.ports.logSlice.send({date: Date.now(), position, length, value}))
  })
  activeBackend.onChange(change => app.ports.logChanged.send({date: Date.now(), ...change}))

  const speechCapable = !!window.speechSynthesis && !!window.SpeechSynthesisUtterance
  // let sayWatching = true // useful for testing. uncomment me, upload a file, and i'll say all lines in that file
  let sayWatching = false
  let volume = null
  app.ports.sendSettings.subscribe(s => {
    volume = s.volume
    settings.write(s)
  })
  app.ports.events.subscribe(event => {
    if (volume == null) {
      console.error('speech is happening, but volume not initialized')
    }
    if (event.type === 'progressComplete' && !sayWatching && (event.name === 'history' || event.name === 'history:example')) {
      sayWatching = true
      say({say: 'mapwatch now running.', volume})
    }
    if (event.type === 'joinInstance' && sayWatching && event.say) {
      say({say: event.say, volume})
    }
  })
}

class Settings {
  constructor(key, storage) {
    this.key = key
    this.storage = storage
  }
  read() {
    return JSON.parse(this.storage.getItem(this.key))
  }
  readDefault(default_) {
    try {
      return this.read()
    }
    catch (e) {
      console.warn(e)
      return default_
    }
  }
  write(json) {
    this.storage.setItem(this.key, JSON.stringify(json))
  }
  clear() {
    this.storage.removeItem(this.key)
  }
}
function createFlags({backend, settings, qs}) {
  const loadedAt = Date.now()
  const tickStart = isNaN(parseInt(qs.tickStart)) ? null : parseInt(qs.tickStart)
  const tickOffset = tickStart ? loadedAt - tickStart : 0
  const logtz = isNaN(parseFloat(qs.logtz)) ? null : parseFloat(qs.logtz)
  if (tickOffset) console.log('tickOffset set:', {tickOffset, tickStart, tickStartDate: new Date(tickStart)})
  return {
    loadedAt,
    tickOffset,
    changelog,
    version,
    logtz,
    settings: settings.readDefault({}),
    isBrowserSupported: !!window.FileReader,
    // isBrowserSupported: false,
    platform: backend.platform,
    datamine,
  }
}
function fetchExample(qs) {
  console.log("fetching example file: ", qs.example, qs)
  // show a progress spinner, even when we don't know the size yet
  // var sendProgress = logReader.progressSender(app, flags.loadedAt, "history:example")(0, 0, flags.loadedAt)
  return fetch("./examples/"+qs.example)
  .then(res => {
    if (res.status < 200 || res.status >= 300) {
      return Promise.reject("non-200 status: "+res.status)
    }
    return res.blob()
  })
  .then(blob => blob.text())
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
registerServiceWorker.unregister()
