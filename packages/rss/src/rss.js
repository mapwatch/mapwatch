const RSS = require('rss')
const {promisify} = require('util')
const fs = require('fs')
const parseChangelog = require('./changelog-md')

const hostname = 'https://mapwatch.github.io'
// promisify(fs.readFile)('./example-CHANGELOG.md')
promisify(fs.readFile)('../../CHANGELOG.md')
.then(parseChangelog({limit: 20}))
.then(({header, entries}) => {
  const feed = new RSS({
    ...header,
    feed_url: hostname+'/rss',
    site_url: hostname+'/#/changelog',
    image_url: hostname+'/favicon.jpeg',
  })
  for (let entry of entries) {
    feed.item({
      ...entry,
      url: hostname+'/#/changelog'+(entry.ymd ? '/'+entry.ymd : ''),
    })
  }
  return feed.xml({indent: true})
})
.then(console.log)
