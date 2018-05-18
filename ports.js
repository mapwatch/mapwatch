var app = Elm.Main.fullscreen({loadedAt: Date.now()})

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
// read line-by-line.
function readLines(file, config) {
  var chunkSize = config.chunkSize || Math.pow(2, 20)
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
app.ports.inputClientLogWithId.subscribe(function(id) {
  var files = document.getElementById(id).files
  if (files.length <= 0) return
  var file = files[0]
  var sendProgress = progressSender(Date.now())
  sendProgress(0, file.size, Date.now())
  readLines(file, {onLine: sendLine, onDone: sendLine, onChunk: sendProgress})
})
