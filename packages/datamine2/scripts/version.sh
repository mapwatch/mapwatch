#!/bin/sh -eu
cd "`dirname "$0"`/.."

mkdir -p third-party dist

# fetch the latest poe patch version
(cd third-party && rm -f latest.txt && wget https://raw.githubusercontent.com/poe-tool-dev/latest-patch-version/main/latest.txt)
cp -f third-party/latest.txt dist/version.txt