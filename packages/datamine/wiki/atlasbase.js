// atlasbase.json used to be done semi-manually. That still works, but you should use `yarn wiki` instead.
// in the js console of https://pathofexile.gamepedia.com/List_of_atlas_base_items, run:
function wikiTableCells(table) {
  return {
    // updated: new Date().toString(),
    data: Array.from($('tr:not(:first-child)', table)).map(tr => process(Array.from(tr.children))),
  }
}
function cellItems(cell) {
  return $("a", cell).not(".item-stats a").map((i,a) => $(a).text()).get()
}
function process(row) {
  const region = row[0].textContent
  const white = cellItems(row[1])
  const yellow = cellItems(row[2])
  const red = cellItems(row[3])
  return {region, loot: {red, yellow, white}}
}
wikiTableCells($('.wikitable')[1])
console.log(JSON.stringify(wikiTableCells($('.wikitable')[1]), null, 2))
