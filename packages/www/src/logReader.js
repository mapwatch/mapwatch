function processFile(app, backend, progressName, position, length) {
  const sendProgress = progressSender(app, Date.now(), progressName)
  // sendProgress(0, fileSlice.size, Date.now())
  readLines(backend, {
    position,
    length,
    onLine: line => sendLine(app, line),
    onChunk: sendProgress,
    onDone: tail => {
      sendLine(app, tail)
      if (progressName !== "watch") {
        watchChanges(app, backend)
      }
    },
  })
}
function watchChanges(app, backend) {
  backend.onChange(({size, oldSize}) => {
    console.log("Logfile updated:", oldSize, "to", size)
    if (oldSize > size) {
      // uncommon; user might have deleted it
      console.error("Logfile shrank? I'm confused, I quit")
      backend.close()
    }
    else {
      processFile(app, backend, "watch", oldSize, size - oldSize)
    }
  })
}
// TODO use datamined text for "you have entered" instead of hardcoding,
// to support other languages
const LOGLINE_FILTER = /Connecting to instance server|: You have entered|LOG FILE OPENING|你已進入：/
// ignore chat messages, don't want people injecting commands.
// #global, %party, @whisper, $trade, &guild
// TODO: local has no prefix! `[A-Za-z_\-]+:` might work, needs more testing
const LOGLINE_BLACKLIST = /] [#%@$&]/
function sendLine(app, line) {
  if (LOGLINE_FILTER.test(line) && !LOGLINE_BLACKLIST.test(line)) {
    app.ports.logline.send({line: line, date: parseDate(line)})
  }
}
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
const progressSender = (app, startedAt, name) =>
  (val, max, updatedAt) => {
    const progress = {name, val, max, startedAt, updatedAt}
    // console.log('progress', progress)
    app.ports.progress.send(progress)
  }

const MB = Math.pow(2,20)
// read line-by-line.
function readLines(backend, config) {
  const chunkSize = config.chunkSize || 1*MB
  const chunkNum = 0
  const buf = LineBuffer(config.onLine, config.onDone)
  const totalSize = config.length || backend.size()
  function loop(chunkNum) {
    const start = (config.position || 0) + chunkSize * chunkNum
    // don't read past the end
    const length = Math.min(chunkSize, totalSize - chunkSize * chunkNum)
    const end = start + length
    backend.slice(start, length)
    .then(txt => {
      // console.log('read chunk:', txt.length)
      buf.push(txt)
      if (config.onChunk) config.onChunk(Math.min(end, totalSize), totalSize, Date.now())
      if (end < totalSize) {
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

module.exports = {progressSender, processFile, MB}
