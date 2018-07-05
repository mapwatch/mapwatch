// Copied from electron quickstart.
const electron = require('electron')
// Module to control application life.
const app = electron.app
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow

const path = require('path')
const url = require('url')
const argv = require('minimist')(process.argv.slice(2))
const {promisify} = require('util')
const _ = require('lodash/fp')
const debounce = (() => {
  const _debounce = _.debounce.convert({fixed: false})
  return _.curry((opts, wait, fn) => _debounce(wait, fn, opts))
})()

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow

function createWindow () {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    icon: path.join(__dirname, 'node_modules/@mapwatch/www/dist/favicon.jpeg')
  })

  // and load the index.html of the app.
  const initUrl = url.format({
    pathname: path.join(__dirname, 'index.html'),
    protocol: 'file:',
    slashes: true,
    query: {
    },
  })
  console.log(initUrl)
  mainWindow.loadURL(initUrl)

  if (argv.livereload) {
    const child_process = require('child_process')
    const watch = {}
    watch.yarn = child_process.execFile('yarn', ['build:watch'], {cwd: "../www"}, (err) => {
      if (err) {
        console.error('fail', err)
        app.quit()
      }
    })

    const chokidar = require('chokidar')
    watch.chok = chokidar.watch(['.', '../www/dist'], {
      ignored: ['./node_modules'],
      ignoreInitial: true,
    })
    .on('all', debounce({leading: true, trailing: true}, 250, (event, path) => {
      console.log('livereload:', event, path)
      mainWindow.loadURL(initUrl)
    }))
    app.on('quit', () => {
      watch.chok.close()
      watch.yarn.kill()
    })
  }

  // Open the DevTools.
  // mainWindow.webContents.openDevTools()

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
  })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', function () {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow()
  }
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
