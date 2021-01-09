const fetch = require("node-fetch")

async function main() {
  const res = await fetch("https://api.pathofexile.com/leagues", {
    headers: {
      // cloudflare doesn't seem to like node-fetch, but a custom useragent seems to work
      'User-Agent': 'node-fetch_mapwatch-erosson-org',
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
