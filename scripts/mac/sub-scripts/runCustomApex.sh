#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# running custom apex
echo "${yellow}\nRunning apex code from .\scripts\apex\ ... \n----------------------------------------------${default}"
for filename in  ./scripts/apex/*; do
	echo "Running ${filename}"
	sfdx force:apex:execute --apexcodefile $filename
done