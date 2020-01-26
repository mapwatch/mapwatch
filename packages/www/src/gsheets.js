// https://developers.google.com/sheets/api/quickstart/js
const _ = require('lodash')

const API_KEY = "AIzaSyDHXZvdqZF7QsrVtjOtV7TgjTkUfxmdIO0"
const CLIENT_ID = "274178280847-9ejt5ti8lms9eh48h61dd0eeomi25gra.apps.googleusercontent.com"

// Array of API discovery doc URLs for APIs used by the quickstart
var DISCOVERY_DOCS = ["https://sheets.googleapis.com/$discovery/rest?version=v4"];

// Authorization scopes required by the API; multiple scopes can be
// included, separated by spaces.
// var SCOPES = "https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/drive.file";
var SCOPES = "https://www.googleapis.com/auth/spreadsheets";

module.exports.main = function main(app) {
  window.gapi.load('client:auth2', () => {
    window.gapi.client.init({
      apiKey: API_KEY,
      clientId: CLIENT_ID,
      discoveryDocs: DISCOVERY_DOCS,
      scope: SCOPES
    })
    .then(() => {
      // Listen for sign-in state changes.
      gapi.auth2.getAuthInstance().isSignedIn.listen(login => app.ports.gsheetsLoginUpdate.send({login, error: null}))

      // Handle the initial sign-in state.
      app.ports.gsheetsLoginUpdate.send({login: gapi.auth2.getAuthInstance().isSignedIn.get(), error: null})
    })
    .catch(error => {
      app.ports.gsheetsLoginUpdate.send({error, login: null})
    })
  })

  app.ports.gsheetsLogin.subscribe(() => {
    window.gapi.auth2.getAuthInstance().signIn()
  })
  app.ports.gsheetsLogout.subscribe(() => {
    window.gapi.auth2.getAuthInstance().signOut()
  })
  app.ports.gsheetsWrite.subscribe(({spreadsheetId, headers, rows}) => new Promise((resolve, reject) => {
    createOrUpdateSpreadsheet({spreadsheetId})
    .then(thenLog('gsheetsWrite:create'))
    .then(resetSheets)
    .then(res => updateCells({res, headers, rows}))
    .then(res => {
      const {spreadsheetUrl, sheets} = res
      const sheetsByTitle = _.keyBy(sheets, 'properties.title')
      const sheet = sheetsByTitle[MAIN_SHEET]
      res.spreadsheetUrl = sheet
        ? spreadsheetUrl + '#gid=' + sheet.properties.sheetId
        : spreadsheetUrl
      return res
    })
    .then(thenLog('gsheetsWritten'))
    .then(res => app.ports.gsheetsWritten.send({res, error: null}))
    .catch(error => {
      app.ports.gsheetsWritten.send(thenLogError('gsheetsWritten: error', error)({
        res: null,
        error: _.get(error, 'result.error.message')
            || _.get(error, 'message')
            || error+'',
      }))
    })
  }))
}
const MAIN_SHEET = "Mapwatch: Data"
const SHEET_NAMES = [MAIN_SHEET]

function createOrUpdateSpreadsheet({spreadsheetId}) {
  if (!!spreadsheetId) {
    return window.gapi.client.sheets.spreadsheets.get({spreadsheetId})
    // .then(thenLog("spreadsheets.create:get"))
    .then(res => res.result)
  }
  else {
    return window.gapi.client.sheets.spreadsheets.create({
      properties: {
        title: "Mapwatch",
      },
    })
    // .then(thenLog("spreadsheets.create"))
    .then(res => res.result)
  }
}

function resetSheets(res) {
  const {spreadsheetId, sheets} = res
  const sheetsByTitle = _.keyBy(sheets, 'properties.title')
  // .then(thenLog("spreadsheets.update:get"))
  // https://developers.google.com/sheets/api/samples/sheet
  return window.gapi.client.sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    resource: {
      requests: SHEET_NAMES.map(title => {
        const sheet = sheetsByTitle[title]
        if (!!sheet) {
          return {
            updateCells: {
              range: {
                sheetId: sheet.properties.sheetId,
              },
              fields: "userEnteredValue",
            },
          }
        }
        else {
          return {
            addSheet: {
              properties: {
                title,
              },
            },
          }
        }
      }),
    },
  })
  .then(thenLog('resetSheets'))
  .then(() => res)
}
function updateCells({res, headers, rows}) {
  const {spreadsheetId} = res
  return window.gapi.client.sheets.spreadsheets.values.update({
    spreadsheetId,
    range: "'"+MAIN_SHEET+"'!A1:ZZ99999",
    valueInputOption: 'USER_ENTERED',
  }, {
    values: [headers].concat(rows),
  })
  // .then(thenLog('updateCells'))
  .then(() => window.gapi.client.sheets.spreadsheets.get({spreadsheetId}))
  .then(thenLog('updateCells:get'))
  // style: autoresize columns, set a fixed header row
  .then(res =>
    window.gapi.client.sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: res.result.sheets.filter(s => SHEET_NAMES.includes(s.properties.title)).map(sheet => [{
          autoResizeDimensions: {
            dimensions: {
              sheetId: sheet.properties.sheetId,
              dimension: "COLUMNS",
              startIndex: 0,
              endIndex: 999,
            }
          },
        },{
          updateSheetProperties: {
            fields: "gridProperties.frozenRowCount",
            properties: {
              sheetId: sheet.properties.sheetId,
              gridProperties: {frozenRowCount: 1},
            },
          },
        }]).flat(),
      },
    })
    .then(() => res.result)
  )
}

const thenLog = (...prefix) => val => {
  console.log(...prefix, val)
  return val
}
const thenLogError = (...prefix) => val => {
  console.error(...prefix, val)
  return val
}
