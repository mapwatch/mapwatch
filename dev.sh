#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./.dev
rm -rf $dest
mkdir -p $dest
for f in `ls assets`; do
  ln -s `pwd`/assets/$f $dest/
done
elm-live ./src/Main.elm --dir=$dest --output=$dest/elm.js --open
