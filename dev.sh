#!/bin/sh -eux
cd "`dirname "$0"`"
cp ./src/index.html index.html
elm-live src/Main.elm --output=elm.js --open
