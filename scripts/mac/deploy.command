#!/bin/bash

tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

sh ./scripts/mac/sub-scripts/deploy.sh