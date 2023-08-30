#!/bin/sh
set -eu
cd "`dirname "$0"`/.."

rm -rf build

# fetch the latest poe patch version
./scripts/version.sh
SED="s/\"patch\": \"REPLACEME\"/\"patch\": \"`cat dist/version.txt`\"/"

# most data comes from the poe-dat-viewer. configure and run it
mkdir -p build/data/main build/data/lang
sed "$SED" src/main.json > build/data/main/config.json
sed "$SED" src/lang.json > build/data/lang/config.json
(cd build/data/main && pathofexile-dat)
(cd build/data/lang && pathofexile-dat)

# finally, combine the raw pdv files into mapwatch's preferred json format
yarn tsc
node build/mapwatch-from-pdv.js > dist/mapwatch.json

wget 'https://api.pathofexile.com/leagues?type=main' -O dist/leagues.json

# some data comes from scraping other websites, independent of the stuff above
alias node="node --enable-source-maps"
node build/scrape-divcards2.js > dist/divcards2.json
node build/scrape-poedb-map-icons.js > dist/poedb-map-icons.json
