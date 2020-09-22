/** Until PyPoE is working again, export ggpk data as a spreadsheet. */
const _ = require('lodash')
const fs = require('fs').promises
const xlsx = require('xlsx')
const open = require('open')

async function main() {
  const inpath = './dist/all.json'
  const outpath = './dist/all.html'
  const url = "file://"+process.cwd()+outpath

  const rawjson = JSON.parse(await fs.readFile(inpath))
  const json = _.keyBy(rawjson, 'filename')

  const jsonsheet = json['WorldAreas.dat']
  const header = _.map(jsonsheet.header, 'name')
  const data = _.map(jsonsheet.data, row => _.zipObject(header, row))
  .filter(row => /Heist/.test(row.Id))
  console.log(data)
  const sheet = xlsx.utils.json_to_sheet(data, {header})

  const html = xlsx.utils.sheet_to_html(sheet, {})
  await fs.writeFile(outpath, html)
  console.log(outpath, url)
  await open(url)
}
main()
