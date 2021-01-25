const fetch = require("node-fetch")

async function main() {
  const res = await fetch("https://api.pathofexile.com/leagues", {
    headers: {
      // GGG staff asks that user-agents have contact info for the author
      // This is (weakly) enforced by blocking the default node-fetch.
      'User-Agent': 'node-fetch from https://github.com/erosson/mapwatch',
    }
  })
  if (res.status !== 200) {
    const err = await res.text()
    console.error(res, err)
    throw new Error("non-200 status code: "+res.status)
  }
  const data = await res.json()
  // const body = {updated: new Date().toString(), data}
  const body = {data}
  return JSON.stringify(body, null, 2)
}
main().then(console.log)
