#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";


echo "${yellow}\nInstalling packages ... \n----------------------------------------------${default}"
sfdx force:package:install -w 10 -b 10 -r -p 04t2o000001Mx1PAAS