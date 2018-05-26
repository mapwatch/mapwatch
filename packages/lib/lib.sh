#!/bin/sh -eux
cd "`dirname "$0"`"
dest=./dist
rm -rf $dest
mkdir -p $dest
sysconfcpus -n 2 elm-make Main.elm --output=$dest/elm.js
