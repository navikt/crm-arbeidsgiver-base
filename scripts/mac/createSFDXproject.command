#!/bin/bash

tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

sfdx force:project:create --projectname tmp

cp -r tmp/force-app/ force-app/
cp -r tmp/config/ config/
cp tmp/sfdx-project.json .
mkdir .sfdx
echo '{"defaultdevhubusername":"","defaultusername": ""}' > .sfdx/sfdx-config.json

rm -r tmp