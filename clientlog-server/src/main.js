// Tail the PoE client-log and send it to a websocket.
//
// Only minimal logic here. The browser client is the brains of the operation,
// since it's easy to deploy updates.
const Tail = require('tail').Tail
const WebSocket = require('ws')
const http = require('http')
const fs = require('fs')

function log(event, obj) {
  console.log(Object.assign({date: new Date(), event}, obj))
}

class WSServer {
  constructor(server) {
    this.server = server
    this.clients = []

    this.server.on('connection', (ws, req) => {
      let client = {ws, req}
      this.clients.push(client)
      log('connection', client)

      // do nothing with received websocket messages, for now
      client.on('message', message => {
        log('recv', {client, message})
      })
    })
  }

  send(message) {
    log('send', {numClients: clients.length, message})
    for (let client of clients) {
      if (client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message, err => {
          log('send:ERROR', {client, message})
        })
      }
    }
  }
}

class TailSender {
  constructor(tail, send) {
    this.tail = tail
    this.send = send

    this.tail.on('line', data => {
      this.send({type: 'line', data})
    })
    this.tail.on('error', err => {
      this.send({type: 'ERROR', err})
    })
  }
}

const wsserver = new WSServer(new WebSocket.Server({noServer: true}))
const logtail = new TailSender(new Tail('./log.txt'), msg => wsserver.send(msg))

const index = fs.readFileSync('./src/index.html')
const httpserver = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'})
  res.write(index)
  res.end()
})
httpserver.on('upgrade', (request, socket, head) => {
  // connect to the websocket server via the http server.
  // based on https://github.com/websockets/ws example
  wsserver.handleUpgrade(request, socket, head, ws => {
    wsserver.emit('connection', ws, request)
  })
  /*const pathname = url.parse(request.url).pathname

  if (pathname === '/clientlog') {
    wsserver.handleUpgrade(request, socket, head, ws => {
      wsserver.emit('connection', ws, request)
    })
  }
  else {
    socket.destroy()
  }*/
})
httpserver.listen(8080)
