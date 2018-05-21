#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist
rm -rf $dest
mkdir -p $dest
cp ./src/ports.js ./src/main.css ./src/index.html ./examples $dest
elm-make src/Main.elm --output=$dest/elm.js
