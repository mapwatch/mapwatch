#!/usr/bin/env node
const fs = require("fs").promises
const path = require("path")

async function main(schemaPath, jsonRoots) {
  if (!schemaPath) throw new Error("usage: node schema.js SCHEMA_PATH JSON_ROOT...")
  if (!jsonRoots) console.error("j-roots block your path. / Perhaps they can be opened / at a later time.")
  if (!jsonRoots) throw new Error("usage: node schema.js SCHEMA_PATH JSON_ROOT...")

  const schema = JSON.parse((await fs.readFile(schemaPath)).toString())
  // console.log(schema)

  const ret = await Promise.all(Object.entries(schema).map(
    async ([key, fields]) => {
      const datPaths = jsonRoots.map(root => path.join(root, key)+'.json')
      // the first jsonRoot where this file exists
      const datPath = (await Promise.all(
        datPaths.map(p => fs.access(p).then(_ => p).catch(_ => null))
      )).filter(p => p)[0]
      const dat = JSON.parse((await fs.readFile(datPath)).toString())

      const fieldSet = new Set(fields)
      // const body = {...dat, data: dat.data.map(row => Object.fromEntries(fields.map(key => [key, row[key]])))}
      const body = {...dat,
        header: dat.header.filter(h => fieldSet.has(h.name)),
        data: dat.data.map(cols => {
          const row = dat.header
            .map((h, i) => [h.name, cols[i]])
            .filter(([name, _]) => fieldSet.has(name))
            .map(([_, val]) => val)
          if (row.length !== fields.length) {
            console.error(fields, row)
            throw new Error("some schema fields were missing")
          }
          return row
        })
      }
      return body
    })
  )
  console.log(JSON.stringify(ret, null, 2))
}
if (require.main === module) {
  const argv = process.argv.slice(2)
  main(argv[0], argv.slice(1)).catch(e => {
    console.error(e)
    process.exit(1)
  })
}
