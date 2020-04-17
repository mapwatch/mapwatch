// https://developers.google.com/sheets/api/quickstart/js
const _ = require('lodash')

// Oh no, an api key in code! Is this okay? Yes, I think so:
//
// * the api key must be somewhere on the client, even Google's quickstart agrees, so it's already public
// * I don't need a separate dev api key yet, so there's no need to refactor
// * This key is restricted to google sheets for users on my domain, so it's not much use to an attacker (I think)
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
    if (window.electronFlags) {
      // Force electron to show the account chooser
      window.gapi.auth2.getAuthInstance().signIn({prompt: 'select_account'})
    }
    else {
      window.gapi.auth2.getAuthInstance().signIn()
    }
  })
  app.ports.gsheetsLogout.subscribe(() => {
    window.gapi.auth2.getAuthInstance().signOut()
  })
  app.ports.gsheetsDisconnect.subscribe(() => {
    window.gapi.auth2.getAuthInstance().disconnect()
  })
  app.ports.gsheetsWrite.subscribe(({spreadsheetId, title, content}) => new Promise((resolve, reject) => {
    createOrUpdateSpreadsheet({spreadsheetId, title})
    .then(thenLog('gsheetsWrite:create'))
    .then(res => updateCells({res, content}))
    .then(thenLog('gsheetsWrite:updateCells'))
    .then(res => {
      const {spreadsheetUrl, sheets} = res
      const sheetsByTitle = _.keyBy(sheets, 'properties.title')
      const sheet = sheetsByTitle[content[0].title]
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

function createOrUpdateSpreadsheet({spreadsheetId, title}) {
  if (!!spreadsheetId) {
    return window.gapi.client.sheets.spreadsheets.get({spreadsheetId})
    // .then(thenLog("spreadsheets.create:get"))
    .then(res => res.result)
  }
  else {
    return window.gapi.client.sheets.spreadsheets.create({
      properties: {
        title,
      },
    })
    // .then(thenLog("spreadsheets.create"))
    .then(res => res.result)
  }
}

function updateCells({res, content}) {
  const {spreadsheetId, sheets} = res
  const sheetsByTitle = _.keyBy(sheets, 'properties.title')
  return window.gapi.client.sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    resource: {
      requests: content.map(({title, headers, rows}, i) => {
        const sheet = sheetsByTitle[title]
        const sheetId = sheet
          ? sheet.properties.sheetId
          // guess a new id that's probably not taken
          // TODO: could guarantee this by doing a separate batch update and letting sheets assign ids
          : 69420 + i
        const resetSheet = sheet
          ? {
              // sheet with this name exists - clear all cells
              updateCells: {
                range: {sheetId},
                fields: "userEnteredValue",
              },
            }
          : {
              addSheet: {
                properties: {sheetId, title},
              },
            }
        return [resetSheet, {
          updateCells: {
            range: {sheetId},
            fields: "userEnteredValue",
            rows: headers.map(hs => ({values: hs.map(h => ({userEnteredValue: {stringValue: h}}))}))
            // cell values are rendered by Elm as {userEnteredValue: {stringValue: x}}, for example.
            // This ties them to gsheets, but allows full control over formatting.
            // https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/other#ExtendedValue
            .concat(rows.map(cs => ({values: cs}))),
          },
        },{
          autoResizeDimensions: {
            dimensions: {
              sheetId,
              dimension: "COLUMNS",
              startIndex: 0,
              endIndex: 999,
            }
          },
        },{
          updateSheetProperties: {
            fields: "gridProperties.frozenRowCount",
            properties: {
              sheetId,
              gridProperties: {frozenRowCount: headers.length},
            },
          },

        }]
      }).flat(),
    },
  })
  .then(() => res)
}

const thenLog = (...prefix) => val => {
  console.log(...prefix, val)
  return val
}
const thenLogError = (...prefix) => val => {
  console.error(...prefix, val)
  return val
}
