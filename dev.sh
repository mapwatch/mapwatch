#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./.dev
rm -rf $dest
mkdir -p $dest
ln -s `pwd`/src/index.html $dest/index.html
ln -s `pwd`/src/ports.js $dest/ports.js
elm-live ./src/Main.elm --dir=$dest --output=$dest/elm.js --open
