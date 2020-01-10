/**
 * All code that runs in web browsers, but not the Electron app.
 */
function MemoryBackend(text) {
  function close() {
    return Promise.resolve()
  }
  function size() {
    return text.length
  }
  function onChange() {
    // no-op, MemoryBackend doesn't change
  }
  function slice(position, length) {
    return Promise.resolve(text.slice(position, position + length))
  }
  return {
    platform: "memory",
    // no 'open' functions
    close,
    slice,
    size,
    onChange,
  }
}
module.exports = {MemoryBackend}
