import '@fluent/web'
import '@fortawesome/fontawesome-free/css/all.css';
import 'sakura.css/css/sakura-vader.css';
import './main.css';
// import { Elm } from '../.elm-spa/defaults/Main.elm';
import { Elm } from './Main.elm';
import * as analytics from './analytics'
import * as gsheets from './gsheets'
import * as util from './util'
import { BrowserBackend } from './browserBackend'
import { BrowserNativeFSBackend } from './browserNativeFSBackend'
import { MemoryBackend } from './memoryBackend'
import datamine from './datamine'
import fs from 'fs'

// import these as raw text during parcel builds.
// https://parceljs.org/features/node-emulation/#inlining-fs.readfilesync
const changelog = fs.readFileSync(__dirname + '/../dist/CHANGELOG.md', 'utf8')
const privacy = fs.readFileSync(__dirname + '/../dist/PRIVACY.md', 'utf8')
// version.txt is created by by `yarn _build:version`
const version = fs.readFileSync(__dirname + '/../dist/version.txt', 'utf8')
// console.log({ changelog, privacy, version })


// Be careful with timezones throughout this file. Use Date.now(), not new Date(),
// for data sent to Elm: no risk of getting timezones involved that way.

const SETTINGS_KEY = 'mapwatch'
const MB = Math.pow(2, 20)

function main() {
  if (window.electronPreloadError) {
    console.error(window.electronPreloadError)
    document.write(window.electronPreloadError)
    return
  }

  const qs = util.parseQS(document.location)
  const backend = createBackend(qs)
  const settings = new Settings(SETTINGS_KEY, window.localStorage)
  const electronFlags = window.electronFlags || null
  const flags = createFlags({ backend, settings, qs, electronFlags })
  const app = Elm.Main.init({ flags })

  const analyticsFlags = {
    backend: backend.platform,
    websiteVersion: version,
    electronVersion: (window.electronFlags || {}).version || null,
  }
  analytics.main(app, analyticsFlags)
  gsheets.main(app, backend.platform, version)

  console.log('init', { backend, flags, electronFlags, analyticsFlags, datamine, qs })

  let activeBackend = backend
  let localStorageWrapper = {
    // electron contextIsolation insists on some real weirdness, man.
    // localStorage is perfectly safe to access from nodejs code, where I've
    // already been super-extra-careful about fs access.
    getItem: (key) => localStorage.getItem(key),
    setItem: (key, val) => localStorage.setItem(key, val),
  }
  if (qs.example) {
    fetchExample(qs)
      .then(text => {
        // logReader.processFile(app, MemoryBackend(text), "history:example")
        activeBackend = MemoryBackend(text)
        console.log('example', activeBackend)
        app.ports.logOpened.send({ date: Date.now(), size: activeBackend.size() })
      })
  }
  else {
    backend.autoOpen(20 * MB, localStorageWrapper)
      .then(opened => {
        if (opened) {
          // logReader.processFile(app, backend, "history")
          app.ports.logOpened.send({ date: Date.now(), size: backend.size() })
        }
      })
  }
  app.ports.fileSelector.subscribe(config => {
    console.log('selector', backend)
    backend.select().then(fileSelected(config))
  })
  app.ports.logSelected.subscribe(config => {
    const files = document.getElementById(config.id).files
    if (files.length > 0) {
      fileSelected(config)(files[0])
    }
  })
  function fileSelected(config) {
    const maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
    return file => {
      activeBackend = backend
      backend.open(file, maxSize, localStorageWrapper)
        .then(() => {
          // logReader.processFile(app, backend, "history")
          app.ports.logOpened.send({ date: Date.now(), size: backend.size() })
        })
    }
  }
  app.ports.logSliceReq.subscribe(({ position, length }) => {
    // console.log('logSliceReq', activeBackend)
    activeBackend.slice(position, length)
      .then(value => app.ports.logSlice.send({ date: Date.now(), position, length, value }))
  })
  app.ports.logSlicePageReq.subscribe(({ position, length }) => {
    // console.log('logSlicePageReq', activeBackend)
    activeBackend.slice(position, length)
      .then(value => app.ports.logSlicePage.send({ date: Date.now(), position, length, value }))
  })
  activeBackend.onChange(change => app.ports.logChanged.send({ date: Date.now(), ...change }))

  const speechCapable = !!window.speechSynthesis && !!window.SpeechSynthesisUtterance
  app.ports.sendSettings.subscribe(s => {
    settings.write(s)
  })
  app.ports.events.subscribe(event => {
    if (event && event.say) {
      say(event.say)
    }
  })
  app.ports.debugNotification.subscribe(args => {
    // Notification.requestPermission().then(() => {
    const n = new Notification(...args)
    console.log('debugNotification', args, n)
    // })
  })
}

function createBackend(qs) {
  // The Electron preload script sets window.backend. This is the only way we
  // distinguish the Electron version from the browser version.
  if (window.backend) {
    return window.backend
  }
  if (qs.backend === 'www-nativefs') {
    return new BrowserNativeFSBackend()
  }
  return new BrowserBackend()
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
function createFlags({ backend, settings, qs, electronFlags }) {
  const loadedAt = Date.now()
  const tickStart = isNaN(parseInt(qs.tickStart)) ? null : parseInt(qs.tickStart)
  const tickOffset = tickStart ? loadedAt - tickStart : 0
  const logtz = isNaN(parseFloat(qs.logtz)) ? null : parseFloat(qs.logtz)
  if (tickOffset) console.log('tickOffset set:', { tickOffset, tickStart, tickStartDate: new Date(tickStart) })
  return {
    loadedAt,
    tickOffset,
    changelog,
    privacy,
    version,
    logtz,
    settings: settings.readDefault({}),
    isBrowserSupported: !!window.FileReader,
    // isBrowserSupported: false,
    platform: backend.platform,
    datamine,
    electronFlags,
  }
}
function fetchExample(qs) {
  console.log("fetching example file: ", qs.example, qs)
  // show a progress spinner, even when we don't know the size yet
  // var sendProgress = logReader.progressSender(app, flags.loadedAt, "history:example")(0, 0, flags.loadedAt)
  return fetch("./examples/" + qs.example)
    .then(res => {
      if (res.status < 200 || res.status >= 300) {
        return Promise.reject("non-200 status: " + res.status)
      }
      return res.blob()
    })
    .then(blob => blob.text())
    .catch(function (err) {
      console.error("Error fetching example:", err)
    })
}

function say(args) {
  if (args.volume > 0) {
    console.log('say', args)
    // console.log(window.speechSynthesis.getVoices())
    var u = new window.SpeechSynthesisUtterance(args.text)
    u.volume = Math.max(0, Math.min(1, args.volume))
    window.speechSynthesis.speak(u)
  }
}

main()

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.ready.then(registration => {
    registration.unregister();
  });
}