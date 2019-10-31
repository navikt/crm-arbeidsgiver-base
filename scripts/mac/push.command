#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# init
tput reset
cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

echo "${yellow}\nPulling from default scratch org ... \n----------------------------------------------${default}"
sfdx force:source:push -f