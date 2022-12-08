function xpathList(xpath, root) {
  const result = document.evaluate(xpath, root || document.body, null, XPathResult.ANY_TYPE, null)
  const ret = []
  let item 
  while (item = result.iterateNext()) {
    ret.push(item)
  }
  return ret
}
function byHeaders(headerRow, body) {
  const headers = Array.from(headerRow.children).map(el => el.textContent)
  return body.map(row => {
    return Object.fromEntries(headers.map((h, i) => [h, row.children[i]]))
  })
}

const header = xpathList("//*[@id='MapsList']//thead//tr")[0]
const body = xpathList("//*[@id='MapsList']//tbody//tr")
const rows = byHeaders(header, body)
const json = (rows
.filter(row => row.Icon && row.Icon.children && row.Icon.children[0])
.map(row => ({
  'name': row.Name.textContent,
  'icon': row.Icon.children[0].children[0].src,
})))
console.log(JSON.stringify(json, null, 2))
