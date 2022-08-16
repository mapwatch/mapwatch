// no `import` statements, this is used by both `tests/elm-string-from-file.js` and `src/index.js`
const datamine = require('../../datamine2/dist/mapwatch.json')
const leagues = require('../../datamine2/dist/leagues.json')
const divcards = require('../../datamine2/dist/divcards.json')

module.exports = {datamine, leagues, wiki: {divcards}}
