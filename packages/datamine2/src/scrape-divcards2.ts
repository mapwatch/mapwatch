import fetch from 'node-fetch'

async function main() {
  // The original scrape-divcards.ts screen-scraped the poewiki html for the data we need.
  // But there's no need for screen scraping, poewiki has json output
  // TODO: we'll need to paginate this someday, limit is 500 results and there's 400ish div cards today (2022-08)
  // https://www.poewiki.net/wiki/List_of_divination_cards
  // https://www.poewiki.net/wiki/Template:Query_base_items
  // https://www.poewiki.net/wiki/Special:CargoQuery?title=Special%3ACargoQuery&tables=items%2C+&fields=items.name%2C+items.description%2C+items.drop_areas%2C+&where=items.class_id%3D%22DivinationCard%22&join_on=&group_by=&having=&order_by%5B0%5D=&order_by_options%5B0%5D=ASC&limit=&offset=&format=json

  // const res = await fetch("https://www.poewiki.net/api.php?action=cargoquery&limit=500&format=json&tables=items&fields=name,description,drop_areas&where=class_id=\"DivinationCard\"")
  // sadly, divcard descriptions are pretty useless - very wiki-specific. drop locations are enough
  const res = await fetch("https://www.poewiki.net/api.php?action=cargoquery&limit=500&format=json&tables=items&fields=name,drop_areas&where=class_id=\"DivinationCard\"")
  const json = await res.json()
  console.log(JSON.stringify(json, null, 2))
}
main().catch(err => {
  console.error(err)
  process.exit(1)
})