// require('./elm.js').Main.worker()
const {promisify} = require('util')
const fs = require('fs')
const _ = require('lodash')

function parseGems(json) {
  return _.chain(json)
  .get('items')
  .map(i => i.socketedItems)
  .flatten()
  .filter(g => !!g && !!g.additionalProperties)
  .map(g => {
    const props = _.keyBy(g.properties, 'name')
    const aprops = _.keyBy(g.additionalProperties, 'name')
    const exps = aprops.Experience.values[0][0].split('/')
    const exp = parseInt(exps[0])
    const maxExp = parseInt(exps[1])
    const level = parseInt(props.Level.values[0][0])
    return {
      id: g.id,
      name: g.typeLine,
      level,
      exp,
      maxExp,
    }
  })
  .keyBy('id')
  .value()
}
function compareGems(snap1, snap2) {
  return _.chain(snap1)
  .mapValues((gem1, key) => {
    const gem2 = snap2[key]
    if (!gem2 || !_.isEqual(_.omit(gem1, 'exp'), _.omit(gem2, 'exp')) || gem1.level >= 20) return null
    return gem2 ? Object.assign({}, gem1, {exp: {before: gem1.exp, after: gem2.exp}}) : null
  })
  .pickBy()
  .value()
}
function diffGemExp(gemPairs) {
  return _.chain(gemPairs)
  // exp-diff for each gem-pair
  .values()
  .map(({exp: {before, after}}) => after - before)
  // return the most popular exp-diff value
  .countBy()
  .entries()
  .maxBy((count, key) => count)
  .get(0)
  .value()
}

function main() {
  promisify(fs.readFile)('./test-response.txt')
  .then(JSON.parse)
  .then(parseGems)
  .then(gems => compareGems(gems, gems))
  .then(diffGemExp)
  .then(console.log)
  .catch(console.error)
}
main()




// const char = "ButImACreep"
// fetch("https://www.pathofexile.com/character-window/get-items?character=" + encodeUriComponent(char))
// .then(res => res.text())
// .then(text => console.log(JSON.parse(text)))




// fetch('https://www.pathofexile.com/character-window/get-items?character=ButImACreep')
// .then(res => {console.log('res'); return res.text()})
// .then(text => {console.log(JSON.stringify(
// [].concat.apply([], JSON.parse(text)
// .items
// .map(i => i.socketedItems))
// .filter(g => !!g && !!g.additionalProperties)
// .map(g => [g.typeLine, g.properties.filter(p => p.name === 'Level')[0].values[0][0], g.additionalProperties.filter(p => p.name === 'Experience')[0].values[0][0]])
// , null, 2))})
