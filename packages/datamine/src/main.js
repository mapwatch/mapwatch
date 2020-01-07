/** PyPoE exports more data than Mapwatch needs. Filter some of it. */
const _ = require('lodash')
const exportSchema = require('./exportSchema.json')

main()

function main() {
  const chunks = []

  process.stdin
  .setEncoding('utf8')
  .on('data', chunk => {
    chunks.push(chunk)
  })
  .on('end', () => {
    const json = JSON.parse(chunks.join(""))
    // console.log(JSON.stringify(json, null, 2))
    const out = transform(json)
    console.log(JSON.stringify(out, null, 2))
    // console.log(JSON.stringify(out))
  })
}
function transform(jsonList) {
  const json = _.keyBy(jsonList, 'filename')
  return filterSchema(json, exportSchema)
}
function filterSchema(json, schema) {
  return _.mapValues(schema, (cols, filename) =>
    filterCols(cols, json[filename].header.map(c => c.name), json[filename].data)
  )
}
function filterCols(cols, fileCols, rows) {
  const colIndexes = cols.map(col => fileCols.indexOf(col))
  return {
    header: cols,
    data: rows.map(row => colIndexes.map(i => row[i])),
  }
}
