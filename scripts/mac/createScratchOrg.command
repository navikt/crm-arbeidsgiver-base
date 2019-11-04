#!/bin/bash

tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

sh ./scripts/mac/sub-scripts/createBranch.sh
sh ./scripts/mac/sub-scripts/createScratchOrg.sh
sh ./scripts/mac/sub-scripts/pushAllMetadata.sh
sh ./scripts/mac/sub-scripts/openScratchOrg.sh
sh ./scripts/mac/sub-scripts/importPermSets.sh
sh ./scripts/mac/sub-scripts/importDummyData.sh
sh ./scripts/mac/sub-scripts/runCustomApex.sh