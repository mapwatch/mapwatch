const jsdom = require("jsdom")
const path = require("path")
const fs = require("fs").promises

async function main() {
  const jquery = (await fs.readFile(path.join(__dirname, "../../../node_modules/jquery/dist/jquery.js"))).toString()
  const script = (await fs.readFile(path.join(__dirname, "../wiki/divcards.js"))).toString()
  const dom = await jsdom.JSDOM.fromURL("https://pathofexile.gamepedia.com/List_of_divination_cards", {runScripts: "outside-only"})
  dom.window.eval(jquery)
  dom.window.eval(script)
}
main().catch(console.error)
