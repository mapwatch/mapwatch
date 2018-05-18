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
function readLines(file, onLine, onDone, chunkSize) {
  chunkSize = chunkSize || Math.pow(2, 20)
  var chunkNum = 0
  var buf = LineBuffer(onLine, onDone)
  var loop = function(chunkNum) {
    var start = chunkSize * chunkNum
    var end = start + chunkSize
    var slice = file.slice(start, end)
    readFile(slice, function(txt) {
      // console.log('read chunk:', txt.length)
      buf.push(txt)
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
var watcher = null
app.ports.inputClientLogWithId.subscribe(function(id) {
  var files = document.getElementById(id).files
  if (files.length <= 0) return
  var file = files[0]
  readLines(file, sendLine, sendLine)
})
