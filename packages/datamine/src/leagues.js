const fetch = require("node-fetch")

async function main() {
  const res = await fetch("https://api.pathofexile.com/leagues")
  if (res.status !== 200) {
    console.error(res)
    throw new Error("non-200 status code: "+res.status)
  }
  const data = await res.json()
  const body = {updated: new Date().toString(), data}
  return JSON.stringify(body, null, 2)
}
main().then(console.log).catch(console.error)
