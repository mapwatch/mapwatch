#!/bin/sh -eux
cd "`dirname "$0"`"
rm -rf ./dist
mkdir -p ./dist
cp ./ports.js src/index.html ./dist/
elm-make src/Main.elm --output=dist/elm.js
