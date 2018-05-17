var app = Elm.Main.fullscreen({wshost: WSHOST})
app.ports.startWatching.subscribe(function(config) {
  var ws = new WebSocket(config.wshost)
  ws.onopen = function() {
    ws.send(JSON.stringify({
      type: 'INIT',
      clientLogPath: '../Client.txt',
      // send only the interesting log messages. Player chat messages are never interesting.
      blacklistFilter: '\\] #',
      filter: 'Connecting to instance server|: You have entered|LOG FILE OPENING',
    }))
  }
  // console.log(app)
  ws.onmessage = function(event) {
    var msg = JSON.parse(event.data)
    // console.log(msg.data)
    app.ports.logline.send(msg.data)
  }
})
