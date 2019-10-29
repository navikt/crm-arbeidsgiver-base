#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# Installing plugins
echo "${yellow}\nInstalling plugins needed for running script ... \n----------------------------------------------${default}"
mkdir ~/.config/
mkdir ~/.config/sfdx/
cp ./config/unsignedPluginWhiteList.json ~/.config/sfdx/
sfdx plugins:install sfdx-wry-plugin@0.0.9

# converting record types to the current org record type ID
echo "${yellow}\nConverting record types to the current org record type ID ... \n----------------------------------------------${default}"
rm -r ./dummy-data/*.out
for folder in  ./dummy-data/*/; do
	sfdx wry:file:replace -i ${folder%/} -o "${folder%/}.out"
done

# adding all dummy data plans
echo "${yellow}\nImporting dummy data ... \n----------------------------------------------${default}"
for filename in  ./dummy-data/*.out/plan.json; do
	sfdx force:data:tree:import --plan $filename
done