#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist/lib
rm -rf $dest
mkdir -p $dest
elm-make lib/Main.elm --output=$dest/elm.js
