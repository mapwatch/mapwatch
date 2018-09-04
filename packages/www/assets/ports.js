function parseQS(search) {
  var qs = (search||'').split('?')[1]
  var pairs = (qs||'').split('&')
  var ret = {}
  for (var i=0; i<pairs.length; i++) {
    var pair = pairs[i].split('=')
    ret[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
  }
  return ret
}
var qs = parseQS(document.location.search)
var loadedAt = Date.now()
var tickStart = qs.tickStart && new Date(isNaN(parseInt(qs.tickStart)) ? qs.tickStart : parseInt(qs.tickStart))
var tickOffset = qs.tickOffset || tickStart ? loadedAt - tickStart.getTime() : 0
var enableSpeech = !!qs.enableSpeech && !!window.speechSynthesis && !!window.SpeechSynthesisUtterance
if (tickOffset) console.log('tickOffset set:', {tickOffset: tickOffset, tickStart: tickStart})
var app = Elm.Main.init({
  node: document.documentElement,
  flags: {
    loadedAt: loadedAt,
    tickOffset: tickOffset,
    isBrowserSupported: !!window.FileReader,
    // isBrowserSupported: false,
    platform: 'www',
    hostname: location.protocol + '//' + location.hostname,
    url: location.href,
  }
})

// https://github.com/elm/browser/blob/1.0.0/notes/navigation-in-elements.md
window.addEventListener('popstate', function() {
  app.ports.onUrlChange.send(location.href)
})
//app.ports.pushUrl.subscribe(function(url) {
//  history.pushState({}, '', url)
//  app.ports.onUrlChange.send(location.href)
//})
app.ports.replaceUrl.subscribe(function(url) {
  history.replaceState({}, '', url)
  app.ports.onUrlChange.send(location.href)
})

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

if (qs.example) {
  console.log("fetching example file: ", qs.example, qs)
  // show a progress spinner, even when we don't know the size yet
  var sendProgress = progressSender(loadedAt, "history:example")(0, 0, loadedAt)
  fetch("./examples/"+qs.example)
  .then(function(res) {
    if (res.status < 200 || res.status >= 300) {
      return Promise.reject("non-200 status: "+res.status)
    }
    return res.blob()
  })
  .then(function(blob) {
    processFile(blob, blob, "history:example")
  })
  .catch(function(err) {
    console.error("Example-fetch error:", err)
  })
}

// Read client.txt line-by-line, and send it to Elm.
// Why aren't we doing the line-by-line logic in Elm? - because this used to be
// a websocket-server, and might be one again in the future.

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
var filter = /Connecting to instance server|: You have entered|LOG FILE OPENING|你已進入：/
// ignore chat messages, don't want people injecting commands.
// #global, %party, @whisper, $trade, &guild
// TODO: local has no prefix! `[A-Za-z_\-]+:` might work, needs more testing
var blacklist = /] [#%@$&]/
function parseDate(line) {
  // example: 2018/05/13 16:05:37
  // we used to do this in elm, but as of 0.19 it's not possible
  var match = /\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}/.exec(line)
  if (!match) return null
  var ymdhms = match[0].split(/[\/: ]/)
  if (ymdhms.length !== 6) return null
  var iso8601 = ymdhms.slice(0,3).join('-') + 'T' + ymdhms.slice(3,6).join(':')
  // no Z suffix: use the default timezone
  return new Date(iso8601).getTime()
}
function sendLine(line) {
  if (filter.test(line) && !blacklist.test(line)) {
    // console.log('line: ', line)
    app.ports.logline.send({line: line, date: parseDate(line)})
  }
}
function progressSender(startedAt, name) {
  return function (val, max, updatedAt) {
    app.ports.progress.send({name: name, val: val, max: max, startedAt: startedAt, updatedAt: updatedAt})
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
        processFile(file.slice(startSize), file, "watch")
      }
    }
  }, POLL_INTERVAL)
}

function processFile(fileSlice, watchedFile, progressName) {
  if (watcher) clearInterval(watcher)
  var sendProgress = progressSender(Date.now(), progressName)
  // sendProgress(0, fileSlice.size, Date.now())
  readLines(fileSlice, {onLine: sendLine, onChunk: sendProgress, onDone: function(tail) {
    sendLine(tail)
    watchChanges(watchedFile)
  }})
}
app.ports.inputClientLogWithId.subscribe(function(config) {
  var files = document.getElementById(config.id).files
  var maxSize = (config.maxSize == null ? 20 : config.maxSize) * MB
  if (files.length > 0) {
    processFile(files[0].slice(Math.max(0, files[0].size - maxSize)), files[0], "history")
  }
})

function say(text) {
  if (enableSpeech) {
    // console.log(speechSynthesis.getVoices())
    speechSynthesis.speak(new SpeechSynthesisUtterance(text))
  }
}
var sayWatching = true // useful for testing. uncomment me, upload a file, and i'll say all lines in that file
// var sayWatching = false
app.ports.events.subscribe(function(event) {
  if (event.type === 'progressComplete' && !sayWatching && (event.name === 'history' || event.name === 'history:example')) {
    sayWatching = true
    say('mapwatch now running.')
  }
  if (event.type === 'joinInstance' && sayWatching && event.say) {
    say(event.say)
  }
})
