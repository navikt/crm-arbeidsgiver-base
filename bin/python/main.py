# -*- coding: utf-8 -*-
# encoding=utf8

import os, json, shutil, subprocess

print("Moving test data to temp folder...")
tempDir = 'dummy-data/temp/'
if not os.path.exists(tempDir):
    os.mkdir(tempDir)

shutil.copytree("dummy-data/activityTimeline", "dummy-data/temp/activityTimeline", dirs_exist_ok=True)
shutil.copytree("dummy-data/tag", "dummy-data/temp/tag", dirs_exist_ok=True)

print("Getting Record Types...")
with open('dummy-data/temp/RecordTypes.json', 'wt') as recordTypeFile:
    subprocess.run('sfdx force:data:soql:query --query "SELECT Id, SobjectType, DeveloperName FROM RecordType WHERE IsActive=true ORDER BY SObjectType, DeveloperName" --resultformat json', shell=True, stdout=recordTypeFile)

print("Prepering test data...")
with open('dummy-data/temp/RecordTypes.json', 'rt') as recordTypeFile:
    recordTypeData = json.load(recordTypeFile)

with open('dummy-data/temp/activityTimeline/Account.json', 'rt') as accountFileForRead:
    accountData = accountFileForRead.read()

with open('dummy-data/temp/activityTimeline/CustomOpportunities.json', 'rt') as customOpportunityFileForRead:
    customOpportunityData = customOpportunityFileForRead.read()

with open('dummy-data/temp/tag/Accounts-B.json', 'rt') as accountBFileForRead:
    accountBData = accountBFileForRead.read()

with open('dummy-data/temp/tag/Accounts-J.json', 'rt') as accountJFileForRead:
    accountJData = accountJFileForRead.read()

with open('dummy-data/temp/tag/Accounts-O.json', 'rt') as accountOFileForRead:
    accountOData = accountOFileForRead.read()

with open('dummy-data/temp/tag/CustomOpportunities.json', 'rt') as customOpportunityTagFileForRead:
    customOpportunityTagData = customOpportunityTagFileForRead.read()

for recordType in recordTypeData['result']['records']:
    replace = '$R{RecordType.' + recordType['SobjectType'] + '.' + recordType['DeveloperName'] + '}'
    
    if recordType['SobjectType'] == 'Account':
        accountData = accountData.replace(replace, recordType['Id'])
        accountBData = accountBData.replace(replace, recordType['Id'])
        accountJData = accountJData.replace(replace, recordType['Id'])
        accountOData = accountOData.replace(replace, recordType['Id'])
    elif recordType['SobjectType'] == 'CustomOpportunity__c':
        customOpportunityData = customOpportunityData.replace(replace, recordType['Id'])
        customOpportunityTagData = customOpportunityTagData.replace(replace, recordType['Id'])

with open('dummy-data/temp/activityTimeline/Account.json', 'wt') as accountFileForWrite:
    accountFileForWrite.write(accountData)

with open('dummy-data/temp/activityTimeline/CustomOpportunities.json', 'wt') as customOpportunityFileForWrite:
    customOpportunityFileForWrite.write(customOpportunityData)

with open('dummy-data/temp/tag/Accounts-B.json', 'wt') as accountBFileForWrite:
    accountBFileForWrite.write(accountBData)

with open('dummy-data/temp/tag/Accounts-J.json', 'wt') as accountJFileForWrite:
    accountJFileForWrite.write(accountJData)

with open('dummy-data/temp/tag/Accounts-O.json', 'wt') as accountOFileForWrite:
    accountOFileForWrite.write(accountOData)

with open('dummy-data/temp/tag/CustomOpportunities.json', 'wt') as customOpportunityTagFileForWrite:
    customOpportunityTagFileForWrite.write(customOpportunityTagData)

print("Test data prepared...")
print("Inserting test data...")

subprocess.run('sfdx force:data:tree:import -p  dummy-data/temp/activityTimeline/plan.json', shell=True)
subprocess.run('sfdx force:data:tree:import -p  dummy-data/temp/tag/plan.json', shell=True)

print("Test data prepared...")
shutil.rmtree(tempDir)