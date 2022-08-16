import jsdom from "jsdom"
import path from "path"
import fs from "fs/promises"

async function main() {
  const [jquery, script, dom] = await Promise.all([
    fs.readFile(path.join(__dirname, "../../../node_modules/jquery/dist/jquery.js")),
    fs.readFile(path.join(__dirname, "../src/scrape-divcards-browser.js")),
    // jsdom.JSDOM.fromURL("https://pathofexile.gamepedia.com/List_of_divination_cards", {runScripts: "outside-only"}),
    jsdom.JSDOM.fromURL("https://www.poewiki.net/wiki/List_of_divination_cards", {runScripts: "outside-only"}),
  ])
  dom.window.eval(jquery.toString())
  dom.window.eval(script.toString())
}
main().catch(err => {
  console.error(err)
  process.exit(1)
})