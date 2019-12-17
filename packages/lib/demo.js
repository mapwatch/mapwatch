// demonstrate/test a headless mapwatch-as-a-library.
// TODO move this to a separate package, to demonstrate how a real import looks
const mapwatch = require('./dist/main')

const path = "../www/public/examples/stripped-client.txt"
const watchFn = process.env.NO_WATCH ? mapwatch.MapWatcher.history : mapwatch.MapWatcher.watch
const watcher = watchFn(path, {
  // optional - leaving it out reads no history, and watches from the end of the log file
  historySize: process.env.NO_HISTORY ? 0 : 20 * Math.pow(2, 20),
})
watcher.subscribeMapRuns(event => {
  console.log("map run completed", event)
})
