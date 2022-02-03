/**
 * All code that runs in web browsers, but not the Electron app.
 */
function BrowserBackend() {
  const POLL_INTERVAL = 1000
  let file = null
  let fileStart = null
  let size = null
  let watcher = null
  const onChanges = []

  function open(userFile, maxSize) {
    file = userFile
    size = file.size
    fileStart = Math.max(0, size - maxSize)
    watcher = window.setInterval(_pollChanges, POLL_INTERVAL)
    return Promise.resolve({size: size - fileStart})
  }
  // The browser will not notify us if the file changes - but in old versions of
  // Chrome, it will change if the underlying filesystem changes! Poll for it.
  function _pollChanges() {
    if (size !== file.size) {
      const oldSize = size
      size = file.size
      for (let fn of onChanges) {
        fn({oldSize: oldSize - fileStart, size: size - fileStart})
      }
    }
  }
  function close() {
    file = null
    size = null
    if (watcher) {
      window.clearInterval(watcher)
    }
    return Promise.resolve()
  }
  function slice(position, length) {
    if (!file) return Promise.reject("file not opened")
    if (length <= 0) return Promise.reject("length must be positive; got: "+length)
    return file.slice(fileStart + position, fileStart + position + length).text()
  }
  function onChange(fn) {
    onChanges.push(fn)
  }
  return {
    platform: "www",
    // no-op promise, browser cannot autoload
    autoOpen: () => Promise.resolve(null),
    open,
    close,
    size: () => size - fileStart,
    slice,
    onChange,
  }
}
module.exports = {BrowserBackend}
