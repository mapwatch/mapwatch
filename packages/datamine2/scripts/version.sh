#!/bin/sh
set -eu
cd "`dirname "$0"`/.."

mkdir -p dist
cd dist
rm -f version.txt
wget --quiet -O version.txt https://raw.githubusercontent.com/poe-tool-dev/latest-patch-version/main/latest.txt
echo "{\"patch\":\"`cat version.txt`\"}" > version.json