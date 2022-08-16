// no `import` statements, this is used by both `tests/elm-string-from-file.js` and `src/index.js`
const datamine = require('../../datamine2/dist/mapwatch.json')
const leagues = require('../../datamine2/dist/leagues.json')
const atlasbase = require('../../datamine/dist/atlasbase.json')
const divcards = require('../../datamine/dist/divcards.json')
const ultimatum = require('../../datamine/UltimatumModifiers.json')

module.exports = {datamine, leagues, wiki: {atlasbase, divcards}, ultimatum}
