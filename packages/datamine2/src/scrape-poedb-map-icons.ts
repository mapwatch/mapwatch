import jsdom from "jsdom"
import fs from "fs/promises"

async function main() {
  const [script, dom] = await Promise.all([
    fs.readFile(`${__dirname}/../src/scrape-poedb-map-icons-browser.js`),
    jsdom.JSDOM.fromURL("https://poedb.tw/us/Maps", {runScripts: "outside-only"}),
  ])
  dom.window.eval(script.toString())
}
main().catch(err => {
  console.error(err)
  process.exit(1)
})