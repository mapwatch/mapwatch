/**
 * https://github.com/mapwatch/mapwatch/issues/51
 * https://web.dev/native-file-system/ (outdated)
 * https://web.dev/browser-nativefs/
 */
function BrowserNativeFSBackend() {
  const POLL_INTERVAL = 1000
  let nativeFile = null
  let fileStart = null
  let size = null
  let watcher = null
  const onChanges = []

  function select() {
    return window.showOpenFilePicker()
  }
  function open(userFile, maxSize) {
    [nativeFile] = userFile
    return nativeFile.getFile().then(file => {
      size = file.size
      fileStart = Math.max(0, size - maxSize)
      console.log('nativefs-open', {fileStart, size, file})
      watcher = window.setInterval(_pollChanges, POLL_INTERVAL)
      return Promise.resolve({size: size - fileStart})
    })
  }
  // The browser will not notify us if the file changes - but in old versions of
  // Chrome, it will change if the underlying filesystem changes! Poll for it.
  function _pollChanges() {
    nativeFile.getFile().then(file => {
      if (size !== file.size) {
        const oldSize = size
        size = file.size
        for (let fn of onChanges) {
          fn({oldSize: oldSize - fileStart, size: size - fileStart})
        }
      }
    })
  }
  function close() {
    nativeFile = null
    size = null
    if (watcher) {
      window.clearInterval(watcher)
    }
    return Promise.resolve()
  }
  function slice(position, length) {
    if (!nativeFile) return Promise.reject("file not opened")
    if (length <= 0) return Promise.reject("length must be positive; got: "+length)
    return nativeFile.getFile().then(file =>
      file.slice(fileStart + position, fileStart + position + length).text()
    )
  }
  function onChange(fn) {
    onChanges.push(fn)
  }
  return {
    platform: "www-nativefs",
    // no-op promise, browser cannot autoload
    select,
    autoOpen: () => Promise.resolve(null),
    open,
    close,
    size: () => size - fileStart,
    slice,
    onChange,
  }
}
module.exports = {BrowserNativeFSBackend}
