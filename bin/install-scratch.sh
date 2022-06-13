#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

ORG_ALIAS="arbeidsgiver-base"


echo ""
echo "Installing crm-arbeidsgiver-base scratch org ($ORG_ALIAS)"
echo ""

echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u $ORG_ALIAS &> /dev/null
echo ""

echo "Creating scratch org..." && \
sfdx force:org:create -s -f config/project-scratch-def.json -d 7 -a $ORG_ALIAS && \
echo "" && \

echo "Installing dependencies..."
secret=$(jq '.PACKAGE_KEY' env.json -r)
keys="" && for p in $(jq '.packageAliases | keys[]' sfdx-project.json -r); do keys+=$p":"$secret" "; done
sfdx sfpowerkit:package:dependencies:install -u $ORG_ALIAS -r -a -w 60 -k "${keys}"
echo ""

echo "Pushing metadata..."
sfdx force:source:push
echo ""

echo "Assigning permissions..."
sfdx force:user:permset:assign -n Create_reports_and_dashboards
sfdx force:user:permset:assign -n Arbeidsgiver_WarningWrite
sfdx force:user:permset:assign -n Arbeidsgiver_Create_and_share_reportfolders
sfdx force:user:permset:assign -n Arbeidsgiver_Kampanje
sfdx force:user:permset:assign -n Arbeidsgiver_NavApp
sfdx force:user:permset:assign -n Arbeidsgiver_NavTask
sfdx force:user:permset:assign -n Arbeidsgiver_Sykefravaer
sfdx force:user:permset:assign -n Arbeidsgiver_arenaActivity
sfdx force:user:permset:assign -n Arbeidsgiver_base
sfdx force:user:permset:assign -n Arbeidsgiver_contract
sfdx force:user:permset:assign -n Arbeidsgiver_opportunity
sfdx force:user:permset:assign -n Arbeidsgiver_temporaryLayoffs
sfdx force:user:permset:assign -n CRM_LoginFlow
echo ""


echo "Opening org..." && \
sfdx force:org:open
echo ""


EXIT_CODE="$?"
echo ""

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE