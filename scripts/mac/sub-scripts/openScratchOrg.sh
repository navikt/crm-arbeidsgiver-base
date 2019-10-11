#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# opening scratch org
echo "${yellow}\nOpening Scratch Org ... \n----------------------------------------------${default}"
sfdx force:org:open