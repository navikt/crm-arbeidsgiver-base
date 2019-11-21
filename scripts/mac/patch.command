#!/bin/bash

tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

mkdir patch
cp -r .vscode patch/.vscode
mkdir patch/dummy-data
cp dummy-data/README.md patch/dummy-data/README.md
cp -r scripts patch/scripts
cp -r manifest patch/manifest
cp *ignore patch/
cp install.* patch/
cp run.* patch/
cp uncrustify.cfg patch/


zip -r ssdx.zip patch
rm -r patch