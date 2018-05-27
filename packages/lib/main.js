// Node wrapper around Mapwatch's Elm brain, for easier usage by Node callers.
// This won't work in a browser - I haven't written a nice wrapper for that. See ports.js.

const Elm = require('./elm')
const fs = require('fs')
const path = require('path')
const readline = require('readline')

function readSlice(path_, opts) {
  const reader = readline.createInterface({input: fs.createReadStream(path_, opts)})
  const size = opts.end - opts.start
  if (opts.onOpen) opts.onOpen(size)
  if (opts.onLine) reader.on('line', line => opts.onLine(line, size))
  if (opts.onClose) reader.on('close', event => opts.onClose(event, size))
  return reader
}
function watch(path_, opts) {
  let end = null
  // before we start watching, read initial history, determine initial size
  fs.stat(path_, (err, stats) => {
    if (err) return (opts.onError || console.error)(err)
    if (!opts.historySize) {
      // mark the end of the file, and start watching for more immediately; process no history
      end = stats.size
    }
    else {
      // optionally, read some history before we start watching
      readSlice(path_, Object.assign({}, opts, {
        start: Math.max(0, end - opts.historySize),
        end: stats.size,
        onOpen: size => {
          if (opts.onHistoryOpen) opts.onHistoryOpen(size)
          if (opts.onOpen) opts.onOpen(size)
        },
        onClose: (event, size) => {
          if (opts.onHistoryClose) opts.onHistoryClose(event, size)
          if (opts.onClose) opts.onClose(event, size)
          // done reading history, watching can start from that point
          end = stats.size
        },
      }))
    }
  })
  // start watching after we read history
  return fs.watch(path_, event => {
    if (lastSize == null) return  // we're still reading history
    // done reading history, process watches
    fs.stat(path_, (err, stats) => {
      if (err) return (opts.onError || console.error)(err)
      if (stats.size > end) {
        // read the new chunk, from previous-end to new-end
        readSlice(path_, Object.assign({}, opts, {
          start: end,
          end: stats.size,
        }))
        end = stats.size
      }
    })
  })
}

class MapWatcher {
  constructor(elmApp) {
    this.elmApp = elmApp
    this.watcher = null
  }
  subscribeMapRuns(onEvent) {
    this.elmApp.ports.mapRunEvent.subscribe(onEvent)
  }
  pushLogLine(line) {
    this.elmApp.ports.logline.send(line)
  }
  watch(path_, opts={}) {
    if (this.watcher) throw new Error('Already watching. Can only watch once per MapWatcher.')
    this.watcher = watch(path_, Object.assign({}, opts, {
      onLine: line => {
        if (opts.onLine) opts.onLine(line)
        this.pushLogLine(line)
      }
    }))
    return this
  }
}
MapWatcher.watch = function(path_, opts) {
  return new MapWatcher(Elm.Main.worker({
    loadedAt: Date.now(),
    tickOffset: 0,
    isBrowserSupported: true,
    platform: 'library',
  }))
  .watch(path_, opts)
}

module.exports = {Elm, MapWatcher, watch}
