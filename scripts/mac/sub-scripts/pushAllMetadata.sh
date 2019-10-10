#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# push code to search
echo "${yellow}\nPushing all code to Scratch Org ... \n----------------------------------------------${default}"
sfdx force:source:push