#!/bin/bash

# colors
red="\033[31m";
yellow="\033[33m";
default="\033[39m";

# init
echo "${yellow}\nEnter Scratch Org name (non-unique names replaces old ones):${default}"
read -p "> " scratchOrgName

# delete old scratch org
echo "${yellow}\nDo you wanna delete the old scratch org? ${red}(NOTE! The currently active org will NOT be recoverable) ${yellow}[y/n]:${default}"
read -p "> " deleteScratchOrg
if [ "$deleteScratchOrg" = "y" ]
then
	echo "${yellow}\nDeleting the previous scratch org ... \n----------------------------------------------${default}"
	sfdx force:org:delete -p
fi

# creating scratch org
echo "${yellow}\nCreating Scratch Org ... \n----------------------------------------------${default}"
sfdx force:org:create -f ./config/project-scratch-def.json --setalias $scratchOrgName --durationdays 5 --setdefaultusername
org=$(sfdx force:org:display)
while [[ $org == *"cs89.my.salesforce.com/"* ]]
do
	echo "${red}\nDeleting previous Scratch Org (previous was cs89 instance, which contains bugs) ... \n----------------------------------------------${default}"
	sfdx force:org:delete -p
	echo "${yellow}\nCreating new Scratch Org (previous was cs89 instance) ... \n----------------------------------------------${default}"
	sfdx force:org:create -f ./config/project-scratch-def.json --setalias $scratchOrgName --durationdays 5 --setdefaultusername
	org=$(sfdx force:org:display)
done