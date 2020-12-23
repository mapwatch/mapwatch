// divcards.json used to be done semi-manually. That still works, but you should use `yarn wiki` instead.
// in the js console of https://pathofexile.gamepedia.com/List_of_divination_cards , run:
function wikiTableCells(table) {
  return {
    // updated: new Date().toString(),
    data: Array.from($('tr:not(:first-child)', table)).map(tr => process(Array.from(tr.children))),
  }
}
function cellItems(cell) {
  return $("a", cell).not(".c-item-hoverbox__display a").map((i,a) => $(a).text()).get()
}
function process(row) {
  const card = cellItems(row[0])[0]
  // const html = row[2].innerHTML
  // console.log(row[2].innerHTML)
  // const text = cellItems(row[2])[0]
  const texts = $(row[2]).contents().map((i, el) => el.textContent).get()
  const text = texts.map(s => s === "" ? "\n" : s).join("")
  const maps = row[3].textContent.split(" • ").filter(t => t !== "N/A")
  //return {card, maps, loot: {text, html}}
  return {card, maps, loot: {text}}
}
wikiTableCells($('.wikitable')[0])
console.log(JSON.stringify(wikiTableCells($('.wikitable')[0]), null, 2))
