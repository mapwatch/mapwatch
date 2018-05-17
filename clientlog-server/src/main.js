// Tail the PoE client-log and send it to a websocket.
//
// Only minimal logic here. The browser client is the brains of the operation,
// since it's easy to deploy updates.
const Tail = require('tail').Tail
const WebSocket = require('ws')
const Http = require('http')
const Url = require('url')
const Fs = require('fs')
const Readline = require('readline')
const Querystring = require('querystring')

function log(event, obj) {
  console.log(Object.assign({date: new Date(), event}, obj))
}

class TailSender {
  constructor(path, send) {
    this.path = path
    this.valid = false
    this._send = send

    // read existing logfile contents
    let first=true
    Readline.createInterface({
      input: Fs.createReadStream(this.path),
      crlfDelay: Infinity,
    })
    .on('line', data => {
      if (first) {
        first = false
        // for a bit of security, validate that this file looks like PoE client logs before sending anything
        this.valid = data.indexOf('***** LOG FILE OPENING *****') >= 0
        if (!this.valid) log('TailSender:error:notAClientLogPath', this)
      }
      this.send({type: 'line', data})
    })
    .on('close', () => {
      // read new logfile lines as they appear
      this.tail = new Tail(path)
      this.tail.on('line', data => {
        this.send({type: 'line', data})
      })
      this.tail.on('error', err => {
        this.send({type: 'ERROR', err})
      })
    })
  }
  send(msg) {
    if (this.valid) {
      this._send(msg)
    }
  }
}

class WSServer {
  constructor(server) {
    this.server = server
    this.clients = []

    this.server.on('connection', (ws, req) => {
      const url = Url.parse(req.url)
      const q = Querystring.parse(url.query)
      const client = {ws, req, url, q}
      this.clients.push(client)
      log('connection', client)

      client.ws.on('message', json => {
        const msg = JSON.parse(json)
        if (msg.type === 'INIT') {
          const config = msg
          // by default, whitelist-filter nothing/match everything
          const filter = new RegExp(config.filter || '')
          // by default, blacklist-filter everything/match nothing
          const bfilter = config.blacklistFilter ? new RegExp(config.blacklistFilter) : null
          log('recv:init', {client, config, filter, bfilter})
          // TODO: close existing logtail, if any
          client.logtail = new TailSender(config.clientLogPath, line => {
            if (filter.test(line.data) && !(bfilter && bfilter.test(line.data))) {
              client.ws.send(JSON.stringify(line))
            }
          })
        }
        else {
          log('recv:UNKNOWN', {client, msg})
        }
      })
    })
  }
}

const wsserver = new WSServer(new WebSocket.Server({noServer: true}))
const host = 'http://localhost:8000'
const index = Fs.readFileSync('./src/index.html', 'utf8').replace(/\$\{HOST\}/g, host)
const httpserver = Http.createServer((req, res) => {
  const url = Url.parse(req.url)
  const q = Querystring.parse(url.query)
  log('www', {url, q})
  res.writeHead(200, {'Content-Type': 'text/html'})
  res.write(index)
  res.end()
})
httpserver.on('upgrade', (request, socket, head) => {
  // example: https://github.com/websockets/ws
  wsserver.server.handleUpgrade(request, socket, head, ws => {
    wsserver.server.emit('connection', ws, request)
  })
})
httpserver.listen(8080)
