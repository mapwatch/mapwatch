const electron = require('electron')
const path = require('path')
const argv = require('minimist')(process.argv)
const child_process = require('child_process')
const os = require('os')
const {autoUpdater} = require('electron-updater')
const log = require('electron-log')
log.transports.file.level = 'debug'

function main() {
  const win = new electron.BrowserWindow({
    width: 800,
    height: 600,
    icon: path.join(__dirname, '../src/favicon.png'),
    // autoHideMenuBar: true,
    webPreferences: {
      // https://cameronnokes.com/blog/how-to-create-a-hybrid-electron-app/
      preload: path.join(__dirname, "preload.js"),
      // https://electronjs.org/docs/tutorial/security
      enableRemoteModule: false,
      nodeIntegration: false,
      // contextIsolation: true,
      additionalArguments: [JSON.stringify({version: electron.app.getVersion()})],
    }
  })
  win.setMenuBarVisibility(false)
  // https://stackoverflow.com/questions/32402327/how-can-i-force-external-links-from-browser-window-to-open-in-a-default-browser
  win.webContents.on('new-window', (e, url) => {
    console.log('new-window', url)
    e.preventDefault()
    electron.shell.openExternal(url)
  })

  if (argv.spawn_www) {
    const www = child_process.exec('elm-app start --no-browser', {
      // cwd: path.join(__dirname, "node_modules/@mapwatch/www"),
      cwd: "../www",
      env: {...process.env, ELM_DEBUGGER: false},
    })
    // TODO: watch output for "You can now view www in the browser." before loading
    www.stdout.on('data', data => process.stdout.write(data.toString()))
    www.stderr.on('data', data => process.stderr.write(data.toString()))
    www.stderr.on('exit', code => {
      if (code) console.error('www: yarn start failed ('+code+')')
      electron.app.quit()
    })
    electron.app.on('quit', () => {
      console.log('electron kill')
      kill(www)
    })
    process.on('exit', () => {
      console.log('process kill')
      kill(www)
    })
  }

  // https://www.electron.build/auto-update
  autoUpdater.logger = log
  autoUpdater.checkForUpdatesAndNotify()

  // finally, load the app itself
  const url = argv.app_url || 'https://mapwatch.erosson.org'
  console.log({url})
  win.loadURL(url)
}
function kill(ps) {
  // https://stackoverflow.com/questions/32705857/cant-kill-child-process-on-windows
  if (os.platform() === 'win32') {
    child_process.exec('taskkill /pid ' + ps.pid + ' /T /F')
  }
  else {
    ps.kill()
  }
}

electron.app.on('ready', main)
