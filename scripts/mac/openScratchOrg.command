#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# init
tput reset
cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

sfdx force:org:open