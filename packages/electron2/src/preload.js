try {
  main()
}
catch (err) {
  window.electronPreloadError = err
}

function main() {
  const {ElectronBackend} = require('./electronBackend')
  window.backend = ElectronBackend()
  window.electronFlags = JSON.parse(window.process.argv.slice(-1)[0])
}
