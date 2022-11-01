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
sfdx force:user:permset:assign -n ArbeidsgiverFia
sfdx force:user:permset:assign -n ArbeidsgiverStillinger
sfdx force:user:permset:assign -n CRM_LoginFlow
echo ""

# Creating temporary folder for test data files.
echo "Moving test data to temp folder..."
mkdir -p dummy-data/temp
cp -r dummy-data/activityTimeline dummy-data/temp
cp -r dummy-data/tag dummy-data/temp
echo ""

# Getting the Record Types from the new scratch org.
echo "Getting Record Types..."
sfdx force:data:soql:query --query "SELECT Id, SobjectType, DeveloperName FROM RecordType WHERE IsActive=true ORDER BY SObjectType, DeveloperName" --resultformat json > dummy-data/temp/RecordTypes.json
echo ""

# Prepering Activity Timeline test data by replacing RecordType placeholders with correct Ids.
echo "Prepering Activity Timeline test data..."
echo "Prepering Account test data..."
for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/activityTimeline/Account.json"
done
echo ""

echo "Prepering Custom Opportunities test data..."
for p in $(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.CustomOpportunity__c.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/activityTimeline/CustomOpportunities.json"
done
echo ""
echo "Activity Timeline test data prepared..."
echo ""

# Prepering Tag test data by replacing RecordType placeholders with correct Ids.
echo "Prepering Tag test data..."
echo "Prepering Account test data..."
for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-B.json"
done

for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-J.json"
done

for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-O.json"
done
echo ""

echo "Prepering Custom Opportunities test data..."
for p in $(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c") | .DeveloperName' dummy-data/temp/RecordTypes.json);
do
    minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
    replace="\$R{RecordType.CustomOpportunity__c.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
    replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
    sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/CustomOpportunities.json"
done
echo ""

echo "Tag test data prepared..."
echo ""

# Inserting the prepared test data
echo "Inserting test data..."
sfdx force:data:tree:import -p  dummy-data/temp/activityTimeline/plan.json
sfdx force:data:tree:import -p  dummy-data/temp/tag/plan.json
echo ""

echo "Removing temporary files..."
rm -rf dummy-data/temp
echo ""


echo "Opening org..." && \
sfdx force:org:open --path "lightning/app/c__TAG_NAV_default"
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