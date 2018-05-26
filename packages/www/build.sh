#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist
rm -rf $dest
mkdir -p $dest
for f in `ls assets`; do
  cp -r assets/$f $dest
done
sysconfcpus -n 2 elm-make src/Main.elm --output=$dest/elm.js
