/**
 * All code that runs in the Electron app, but not in web browsers.
 *
 * Any native/filesystem access must be encapsulated within this module.
 * For security's sake, do not expose it.
 */
const fs = require('fs').promises
const chokidar = require('chokidar')
const regedit = require('regedit')
const promisify = require('util').promisify
const path = require('path')
const REMEMBERED_KEY = "mapwatch.remembered"

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

  async function autoOpen(maxSize, localStorage) {
    const remembered = localStorage && localStorage.getItem(REMEMBERED_KEY)
    if (remembered) {
      // remember the last manually-opened path. If it fails (poe was moved?),
      // force the user to select another path manually, don't surprise them by
      // picking a new one
      return this.open({path: remembered}, maxSize)
    }
    let paths = await Promise.all([
        await catchAndWarn(windowsRegistryPath(), "windows registry inaccessible: ignoring."),
        "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
        "C:\\Program Files\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
        "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
        "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
        "C:\\Program Files\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
      ].map(path =>
        fs.access(path)
        .then(() => path)
        .catch(err => null)
      ))
    paths = paths.filter(val => !!val)
    // console.log('autoOpen paths', paths)
    if (paths.length) {
      return this.open({path: paths[0]}, maxSize)
    }
    else {
      throw new Error("Couldn't guess client.txt path")
    }
  }
  function open({path}, maxSize, localStorage) {
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
    .then(ret => {
      if (localStorage) {
        localStorage.setItem(REMEMBERED_KEY, path)
      }
      return ret
    })
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

function catchAndWarn(p, w) {
  return p.catch(err => {
    console.warn(w, err)
    return null
  })
}
async function windowsRegistryPath() {
  // throw new Error('oops')
  const KEY = "HKCU\\Software\\GrindingGearGames\\Path of Exile"
  const entry = await promisify(regedit.list)(KEY)
  const dir = entry[KEY].values.InstallLocation.value
  if (dir) {
    return path.join(dir, "logs", "Client.txt")
  }
  else {
    throw new Error("null(ish) windows registry InstallLocation: "+KEY)
  }
}

module.exports = {ElectronBackend}
