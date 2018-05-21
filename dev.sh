#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./.dev
rm -rf $dest
mkdir -p $dest
ln -s `pwd`/src/index.html $dest/
ln -s `pwd`/src/ports.js $dest/
ln -s `pwd`/src/main.css $dest/
ln -s `pwd`/examples $dest/
elm-live ./src/Main.elm --dir=$dest --output=$dest/elm.js --open
