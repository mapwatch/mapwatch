#!/bin/sh -eu
cd "`dirname "$0"`/.."

mkdir -p third-party

# fetch the latest poe patch version
(cd third-party && rm -f latest.txt && wget https://raw.githubusercontent.com/poe-tool-dev/latest-patch-version/main/latest.txt)

# prepare poe-dat-viewer (pdv), the dat file exporter
git clone https://github.com/SnosMe/poe-dat-viewer third-party/poe-dat-viewer || true
(cd third-party/poe-dat-viewer && git pull) || true
(cd third-party/poe-dat-viewer/lib && yarn && yarn tsc)
rm -rf build/data
tsc

# actually export .dat files with pdv
node build/pdv.js --version `cat third-party/latest.txt` --config src/main.json --output build/data/main
node build/pdv.js --version `cat third-party/latest.txt` --config src/lang.json --output build/data/lang

# finally, combine the raw pdv files into mapwatch's preferred json format
mkdir -p dist
node build/mapwatch-from-pdv.js > dist/mapwatch.json