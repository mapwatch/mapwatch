var app = Elm.Main.fullscreen({wshost: WSHOST})
//app.ports.startWatching.subscribe(function(config) {
//  var ws = new WebSocket(config.wshost)
//  ws.onopen = function() {
//    ws.send(JSON.stringify({
//      type: 'INIT',
//      clientLogPath: '../Client.txt',
//      // send only the interesting log messages. Player chat messages are never interesting.
//      blacklistFilter: '\\] #',
//      filter: 'Connecting to instance server|: You have entered|LOG FILE OPENING',
//    }))
//  }
//  // console.log(app)
//  ws.onmessage = function(event) {
//    var msg = JSON.parse(event.data)
//    // console.log(msg.data)
//    app.ports.logline.send(msg.data)
//  }
//})

// Read client.txt and send it to Elm.

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
app.ports.inputClientLog.subscribe(function(id) {
  var files = document.getElementById(id).files
  if (files.length <= 0) return
  var file = files[0]
  // readLines(file, function(line) {console.log("line: ", line)}, function(tail) {console.log("done: ", JSON.stringify(tail))})
  readLines(file, function(line) {
    app.ports.logline.send(line)
  }, function(tail) {
    if (tail) app.ports.logline.send(tail)
  })
})
