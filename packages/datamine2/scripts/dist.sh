#!/bin/sh -eu
cd "`dirname "$0"`/.."

# fetch the latest poe patch version
./scripts/version.sh

# prepare poe-dat-viewer (pdv), the dat file exporter
git clone https://github.com/SnosMe/poe-dat-viewer third-party/poe-dat-viewer || true
(cd third-party/poe-dat-viewer && git pull && git checkout d4ab8484cf57cc6a580ce61e6818c10f4be7d731 && git clean -fd) || true
(cd third-party/poe-dat-viewer/lib && yarn && yarn tsc)
yarn tsc
rm -rf build/data

alias node="node --enable-source-maps"
node build/scrape-divcards.js > dist/divcards.json
node build/scrape-poedb-map-icons.js > dist/poedb-map-icons.json

# actually export .dat files with pdv
node build/pdv.js --version `cat third-party/latest.txt` --config src/main.json --output build/data/main
node build/pdv.js --version `cat third-party/latest.txt` --config src/lang.json --output build/data/lang

# finally, combine the raw pdv files into mapwatch's preferred json format
node build/mapwatch-from-pdv.js > dist/mapwatch.json

wget 'https://api.pathofexile.com/leagues?type=main' -O dist/leagues.json
echo "{\"patch\":\"`cat third-party/latest.txt`\"}" > dist/version.json