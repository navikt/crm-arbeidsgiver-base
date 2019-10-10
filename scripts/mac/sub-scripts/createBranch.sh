#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# asking user if they want to create a new branch
echo "${yellow}\nWould you like a new branch?${default}"
echo "${red}\nIf NO, press enter without any text${default}"
echo "${yellow}\nIf YES, type your branch name${default}"

read  -p "> " branch
if [ ! "$branch" = "" ]
then
	# creating branch
	echo "${yellow}\nCreating a new branch ... \n----------------------------------------------${default}"
  git checkout UAT
  git pull
	git checkout -b SF-$branch UAT
	git push origin SF-$branch
fi