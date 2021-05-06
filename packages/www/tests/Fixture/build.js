const fs = require('fs').promises

fs.writeFile(__dirname+'/Json.elm',
`module Fixture.Json exposing (datamine)
datamine : String
datamine = ${JSON.stringify(JSON.stringify(require('../../src/datamine.js')))}
`)
