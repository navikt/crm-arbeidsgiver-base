#!/bin/bash

tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

sfdx force:auth:web:login -d