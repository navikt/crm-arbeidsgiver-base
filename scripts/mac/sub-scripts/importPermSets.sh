#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# adding all permission sets
echo "${yellow}\nAdding permission sets ... \n----------------------------------------------${default}"
for filename in  ./force-app/main/default/permissionsets/*; do
	filename="${filename##*/}"
	sfdx force:user:permset:assign -n "${filename//.permissionset-meta.xml}"
done