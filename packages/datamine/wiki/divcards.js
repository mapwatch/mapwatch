// divcards.json updates must be done semi-manually.
// in the js console of https://pathofexile.gamepedia.com/List_of_divination_cards , run:
function wikiTableCells(table, mapRow) {
  return {
    updated: new Date().toString(),
    data: Array.from($('tbody tr', table)).map(tr => (mapRow || (id => id))(Array.from(tr.children))),
  }
}
function process(row) {
  const card = row[0].innerText
  const html = row[2].innerHTML
  const text = row[2].innerText
  const maps = row[3].innerText.split(" • ").filter(t => t !== "N/A")
  //return {card, maps, loot: {text, html}}
  return {card, maps, loot: {text}}
}
wikiTableCells($('.wikitable')[0], process)
JSON.stringify(wikiTableCells($('.wikitable')[0], process), null, 2)
