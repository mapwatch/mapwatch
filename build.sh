#!/bin/sh -eux
cd "`dirname "$0"`"
rm -rf ./dist
mkdir -p ./dist
ls .
ls ./src
cat ./src/index.html | HOST='' envsubst > dist/index.html
cp ./ports.js ./dist/
elm-make src/Main.elm --output=dist/elm.js
