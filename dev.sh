#!/bin/sh -eux
cd "`dirname "$0"`"
cat ./src/index.html | HOST='' envsubst > index.html
elm-live src/Main.elm --output=elm.js --open
