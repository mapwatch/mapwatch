/**
 * All code that runs in the Electron app, but not in web browsers.
 *
 * Any native/filesystem access must be encapsulated within this module.
 * For security's sake, do not expose it.
 */
const fs = require('fs').promises
const chokidar = require('chokidar')

function ElectronBackend() {
  // Native file access: this absolutely must be private; class fields aren't
  // good enough. Use a closure instead.
  const POLL_INTERVAL = 1000
  let file = null
  let size = null
  let watcher = null
  let poller = null
  let fileStart = 0
  const onChanges = []

  function autoOpen(maxSize) {
    return Promise.all([
      "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
      "C:\\Program Files\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
      "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
    ].map(path =>
      fs.access(path)
      .then(() => path)
      .catch(err => null)
    ))
    .then(paths => paths.filter(val => !!val))
    .then(paths =>
        paths.length
          ? Promise.resolve(paths[0])
          : Promise.reject("Couldn't guess client.txt path")
    )
    .then(path => this.open({path}, maxSize))
  }
  function open({path}, maxSize) {
    return this.close()
    // TODO restrict filename?
    .then(() => fs.open(path))
    .then(fd => Promise.all([
      Promise.resolve(fd),
      fd.stat(),
    ])
    .then(([fd, stat]) => {
      file = fd
      size = stat.size
      fileStart = Math.max(0, stat.size - maxSize)
      // Chokidar doesn't seem to be working. TODO: why? For now, poll like browserBackend.
      // watcher = chokidar.watch(path, {disableGlobbing: true})
      // watcher.on('change', (path, changed) => _onChange(changed))
      poller = window.setInterval(_pollChanges, POLL_INTERVAL)
      return {size: stat.size}
    }))
  }
  function _pollChanges() {
    return file.stat().then(_onChange)
  }
  function _onChange(changed) {
    if (size !== changed.size) {
      const oldSize = size
      size = changed.size
      // console.log('changed', {oldSize, size, changed})
      for (let fn of onChanges) {
        fn({oldSize: oldSize - fileStart, size: size - fileStart})
      }
    }
  }
  function close() {
    if (poller) {
      window.clearInterval(poller)
    }
    const ps = [
      file ? file.close() : Promise.resolve(),
      watcher ? watcher.close() : Promise.resolve(),
    ]
    file = null
    watcher = null
    return Promise.all(ps)
  }
  function slice(position, length) {
    if (!file) return Promise.reject("file not opened")
    if (length <= 0) return Promise.reject("length must be positive; got: "+length)
    // https://nodejs.org/api/fs.html#fs_filehandle_read_buffer_offset_length_position
    return file.read(Buffer.alloc(length), 0, length, fileStart + Math.max(0, position))
    .then(({buffer, bytesRead}) => buffer.toString())
    //.then(({buffer, bytesRead}) => {
    //  console.log('bytesRead', {bytesRead, length, position}, buffer.toString())
    //  return buffer.toString()
    //})
  }
  function onChange(fn) {
    onChanges.push(fn)
  }
  return {
    platform: "electron",
    autoOpen,
    open,
    close,
    size: () => size - fileStart,
    slice,
    onChange,
  }
}
module.exports = {ElectronBackend}
