#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist/www
rm -rf $dest
mkdir -p $dest
for f in `ls assets`; do
  cp -r assets/$f $dest
done
elm-make src/Main.elm --output=$dest/elm.js
