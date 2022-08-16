function xpathList(xpath, root) {
  const result = document.evaluate(xpath, root || document.body, null, XPathResult.ANY_TYPE, null)
  const ret = []
  let item 
  while (item = result.iterateNext()) {
    ret.push(item)
  }
  return ret
}
function byHeaders(rows) {
  const headers = Array.from(rows.shift().children).map(el => el.textContent)
  return rows.map(row => {
    return Object.fromEntries(headers.map((h, i) => [h, row.children[i]]))
  })
}

const rows = byHeaders(xpathList("//*[@id='MapsList']//tr"))
const json = rows.map(row => ({
  'name': row.Name.textContent,
  'icon': row.Icon.children[0].children[0].src,
}))
console.log(JSON.stringify(json, null, 2))
