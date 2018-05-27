// demonstrate/test a headless mapwatch-as-a-library.
// TODO move this to a separate package, to demonstrate how a real import looks
const mapwatch = require('./dist/main')

const path = "./node_modules/@mapwatch/www/assets/examples/stripped-client.txt"
const watcher = mapwatch.MapWatcher.watch(path, {
  // optional - leaving it out reads no history, and watches from the end of the log file
  historySize: 20 * Math.pow(2, 20),
})
watcher.subscribeMapRuns(event => {
  console.log("map run completed", event)
})
