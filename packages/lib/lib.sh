#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist
rm -rf $dest
mkdir -p $dest
elm-make Main.elm --output=$dest/elm.js
