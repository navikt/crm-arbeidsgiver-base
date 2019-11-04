#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# init
tput reset

cd -- "$(dirname "$BASH_SOURCE")"
cd ../../..

echo "\nAre you in the correct branch to push code from? [y/n]"
read -p "> " isInCorrectBranch
if [ ! "$isInCorrectBranch" = "y" ]
then
	echo "\nSwitch branch, then retry\n"
	exit 0
fi

echo "\nHave you verified that all code works in a NEW scratch org? [y/n]"
read -p "> " isTestedInNewScratchOrg
if [ ! "$isTestedInNewScratchOrg" = "y" ]
then
	echo "\nCreate a new scratch org and push all data to verify everything works, then retry\n"
	exit 0
fi

# TODO add check to verify?
echo "\nHave you verified that all tests are passing and have enough code coverage? [y/n]"
read -p "> " isAllCodeTested
if [ ! "$isAllCodeTested" = "y" ]
then
	echo "\nTest all code, then retry\n"
	exit 0
fi

echo "\nThese are the available orgs to deploy to\n--------------------------------------------"
echo "[Loading ... ]\n"
sfdx force:org:list

echo "\n\nEnter the ALIAS or USERNAME of the org you want to deploy to (typically, you wouldn't deploy to a scratch org, FYI)\n-----------------------------------------"
read -p "> " orgName

# converting source to medadata and creating a zip file
sfdx force:source:convert --rootdir force-app --outputdir deployment_tmp
zip -r -X deployment_tmp.zip deployment_tmp
rm -r deployment_tmp

# deploy to the org
sfdx force:mdapi:deploy --zipfile deployment_tmp.zip --targetusername $orgName --testlevel RunAllTestsInOrg -w 500

# delete remaining files
rm deployment_tmp.zip