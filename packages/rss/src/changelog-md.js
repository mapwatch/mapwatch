const _ = require('lodash/fp')
const marked = require('marked')

function splitBody(text, splitter="\n") {
  const n = text.indexOf("\n")
  return [text.slice(0, n), text.slice(n)]
}
function parseEntry(entry, index) {
  let [title, body] = splitBody(entry)
  body = body.trim()
  // version id can be [bracketed] or not, and could be followed by " - a-date" or not
  const versionMatch = title.match(/^## \[?([\d\w\.\-\_]+)\]?( - |$)/)
  const version = versionMatch ? versionMatch[1] : null
  const dateMatch = title.match(/\d{4}-\d{2}-\d{2}$/)
  const ymd = dateMatch ? dateMatch[0] : null
  const date = dateMatch ? new Date(dateMatch[0]) : null
  return {
    date,
    ymd,
    title: version,
    guid: version,
    body,
    description: marked(body),
  }
}
function parseHeader(header) {
  let [title, body] = splitBody(header)
  title = title.replace(/^# /, '')
  body = body.trim()
  return {
    title,
    body,
    description: marked(body),
  }
}
module.exports = function parseChangelog(opts) {
  const {limit=20} = opts
  return markdown => {
    let [header, ...entries] = (markdown+'').split(/^## /m)
    header = parseHeader(header)
    // if invalid limit, don't apply a limit
    entries = entries.slice(0, limit && limit > 0 ? limit : undefined).reverse().map(entry => '## '+entry).map(parseEntry).reverse()
    const unreleased = _.filter(e => /unreleased/i.test(e.title), entries)[0]
    entries = _.filter(e => e !== unreleased, entries)
    return {header, unreleased, entries}
  }
}
