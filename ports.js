var app = Elm.Main.fullscreen({
  loadedAt: Date.now(),
  isBrowserSupported: !!window.FileReader,
  // isBrowserSupported: false,
})

// Read client.txt line-by-line, and send it to Elm.
// Why aren't we doing the line-by-line logic in Elm? - because this used to be a websocket-server.

function readFile(file, fn) {
  var reader = new FileReader()
  reader.onload = function(e) {
    fn(e.target.result, e)
  }
  reader.readAsText(file, 'utf8')
}
function LineBuffer(onLine, onDone) {
  return {
    buf: "",
    push: function(txt) {
      var buf = this.buf + txt
      var lines = buf.split(/\r?\n/)
      var i=0
      // all but the last line
      while (i < lines.length-1) {
        onLine(lines[i])
        i++
      }
      this.buf = lines[i]
    },
    done: function() {
      if (onDone) onDone(this.buf)
    }
  }
}
var MB = Math.pow(2,20)
// read line-by-line.
function readLines(file, config) {
  var chunkSize = config.chunkSize || 1*MB
  var chunkNum = 0
  var buf = LineBuffer(config.onLine, config.onDone)
  var loop = function(chunkNum) {
    var start = chunkSize * chunkNum
    var end = start + chunkSize
    var slice = file.slice(start, end)
    readFile(slice, function(txt) {
      // console.log('read chunk:', txt.length)
      buf.push(txt)
      if (config.onChunk) config.onChunk(Math.min(end, file.size), file.size, Date.now())
      if (end < file.size) {
        // window.setTimeout(function(){loop(chunkNum+1)}, 1000)
        loop(chunkNum + 1)
      }
      else {
        buf.done()
      }
    })
  }
  loop(0)
}
var filter = /Connecting to instance server|: You have entered|LOG FILE OPENING/
// TODO blacklist other chat-channels, this only ignores global
var blacklist = /] #/
function sendLine(line) {
  if (filter.test(line) && !blacklist.test(line)) {
    // console.log('line: ', line)
    app.ports.logline.send(line)
  }
}
function progressSender(startedAt) {
  return function (val, max, updatedAt) {
    app.ports.progress.send({val: val, max: max, startedAt: startedAt, updatedAt: updatedAt})
  }
}
var watcher = null
var POLL_INTERVAL = 1000
// The HTML file api doesn't seem to have a way to notify me when the file changes.
// We can poll for changes with no user interaction, though!
function watchChanges(file) {
  var startSize = file.size
  watcher = setInterval(function() {
    if (startSize !== file.size) {
      console.log("Logfile updated:", startSize, "to", file.size)
      if (startSize > file.size) {
        console.error("Logfile shrank? I'm confused, I quit")
        if (watcher) clearInterval(watcher)
      }
      else {
        processFile(file.slice(startSize), file)
      }
    }
  }, POLL_INTERVAL)
}
function processFile(fileSlice, watchedFile) {
  if (watcher) clearInterval(watcher)
  var sendProgress = progressSender(Date.now())
  // sendProgress(0, fileSlice.size, Date.now())
  readLines(fileSlice, {onLine: sendLine, onChunk: sendProgress, onDone: function(tail) {
    // console.log("done processing file, watching changes")
    sendLine(tail)
    watchChanges(watchedFile)
  }})
}
app.ports.inputClientLogWithId.subscribe(function(config) {
  var files = document.getElementById(config.id).files
  var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
  if (files.length > 0) {
    processFile(files[0].slice(Math.max(0, files[0].size - maxSize)), files[0])
  }
})
