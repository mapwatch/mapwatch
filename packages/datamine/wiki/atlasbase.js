// atlasbase.json updates must be done semi-manually.
// in the js console of https://pathofexile.gamepedia.com/List_of_atlas_base_items, run:
function wikiTableCells(table, mapRow) {
  return {
    updated: new Date().toString(),
    data: Array.from($('tbody tr', table)).map(tr => (mapRow || (id => id))(Array.from(tr.children))),
  }
}
function process(row) {
  const region = row[0].innerText
  const white = row[1].innerText.split("\n\n\n")
  const yellow = row[2].innerText.split("\n\n\n")
  const red = row[3].innerText.split("\n\n\n")
  return {region, loot: {red, yellow, white}}
}
wikiTableCells($('.wikitable')[1], process)
JSON.stringify(wikiTableCells($('.wikitable')[1], process), null, 2)
