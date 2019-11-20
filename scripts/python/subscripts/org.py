# -*- coding: utf-8 -*-
# encoding=utf8

import subprocess, os, json, sys, time
import subscripts.helper as helper
import subscripts.orgHelper as orgHelper
from yaspin import yaspin

path, ext = helper.definePathAndExtension()


def createScratchOrg(mainMenu):

	scratchOrgName = helper.askForInput( [ ["Enter Scratch Org name (non-unique names replaces old ones)", [ helper.c.y ]] ] )
	deletePrevious = helper.askForInput( [ 
		["Do you wanna delete the old scratch org? [y/n]", [ helper.c.y ]],
		["(NOTE! The currently active org will NOT be recoverable)", [ helper.c.r, helper.c.BOLD ]]
	 ] )

	helper.clear()

	if(deletePrevious == "y"):
		helper.startLoading("Deleting default Scratch Org")
		helper.tryCommandWithException(
			["sfdx force:org:delete -p"],
			False, False)

	helper.startLoading("Creating new Scratch Org")
	error = helper.tryCommandWithException(
		["sfdx force:org:create " + 
		"-f ./config/project-scratch-def.json " + 
		"--setalias {} ".format(scratchOrgName) + 
		"--durationdays 5 " + 
		"--setdefaultusername"],
		True, True)
	if (error): return

	helper.startLoading("Pushing metadata")
	error = helper.tryCommandWithException( ["sfdx force:source:push"], True, True)
	if (error): return

	helper.startLoading("Opening Scratch Org")
	error = helper.tryCommandWithException(["sfdx force:org:open"], False, False)

	helper.startLoading("Assigning all permission sets")
	orgHelper.fetchPermsets()
	commands = [] 
	for permset in orgHelper.fetchPermsets():
		commands.append("sfdx force:user:permset:assign -n " + permset)
	error = helper.tryCommandWithException(commands, True, True)
	if (error): return

	helper.startLoading("Importing dummy data")
	error = orgHelper.importDummyData()
	if (error): return

	helper.startLoading("Running Apex code from ./scripts/apex")
	commands = [] 
	for apexCode in helper.fetchFilesFromFolder("./scripts/apex/", True):
		commands.append("sfdx force:apex:execute --apexcodefile " + apexCode)
	error = helper.tryCommandWithException(commands, True, True)

	helper.updateMenuInformation(mainMenu)
	helper.pressToContinue(False, 20)


def openScratchOrg(mainMenu):
	helper.startLoading("Opening Scratch Org")
	error = helper.tryCommandWithException(["sfdx force:org:open"], True, True)
	helper.pressToContinue(False, 10)


def deleteScratchOrg(mainMenu):
	text = helper.col("Which Scratch Org do you want to delete?", [helper.c.r, helper.c.BOLD])
	org = orgHelper.askUserForOrgs(False, mainMenu, text)
	deleteScratchOrg = helper.askForInput( [ ["Are you sure you want to delete {}? {}[y/n]".format(org, helper.c.y), [ helper.c.r, helper.c.BOLD ]] ] )
	if(deleteScratchOrg == "y"):
		print()
		helper.startLoading("Deleting Scratch Org")
		error = helper.tryCommandWithException(["sfdx force:org:delete -p -u " + org], True, True)
		helper.updateMenuInformation(mainMenu)
	helper.pressToContinue(False, 10)


def changeDefaultScratchOrg(mainMenu):
	
	text = helper.col("Which Scratch Org do you want to set as your default?", [helper.c.y])
	org = orgHelper.askUserForOrgs(False, mainMenu, text)
	

	if (org):
		data = helper.getDataFromJson(".sfdx/sfdx-config.json")

		tmp = data["defaultusername"]
		data["defaultusername"] = org

		with open(".sfdx/sfdx-config.json", "w") as jsonFile:
			json.dump(data, jsonFile)

		print(helper.col("\nSuccessfully changed default scratch org.", [helper.c.y]))
		print(helper.col("Pushing and pulling will now be directed to '{}'".format(org), [helper.c.ly]))
		helper.updateMenuInformation(mainMenu)
	else:
		print(helper.col("\nThe default org was NOT changed.", [helper.c.y]))
	helper.pressToContinue(False, 10)


def changeDefaultOrg(mainMenu):
		
	text = helper.col("Which Org do you want to set as your default? (Used for Scratch Org creation)", [helper.c.y])
	org = orgHelper.askUserForOrgs(True, mainMenu, text)
	
	if (org):
		data = helper.getDataFromJson(".sfdx/sfdx-config.json")

		tmp = data["defaultdevhubusername"]
		data["defaultdevhubusername"] = org

		with open(".sfdx/sfdx-config.json", "w") as jsonFile:
			json.dump(data, jsonFile)

		print(helper.col("\nSuccessfully changed default org.", [helper.c.y]))
		print(helper.col("Scratch orgs will now be created from '{}'".format(org), [helper.c.ly]))
	else:
		print(helper.col("\nThe default org was NOT changed.", [helper.c.y]))
	helper.pressToContinue(False, 10)


def seeScratchOrgStatus(mainMenu):

	helper.startLoading("Loading Scratch Org details")
	details = subprocess.check_output(["sfdx", "force:org:display", "--json"])
	helper.stopLoading()
	jsonOutput = json.loads(details)

	pre = helper.c.BOLD
	post = helper.c.ENDC

	rows = []

	if ("alias" in jsonOutput['result']):
		rows.append(["Alias", jsonOutput['result']['alias']])
	rows.append(["Username", jsonOutput['result']['username']])
	
	days = ("{} days (next {}, on {})".format(
		helper.convertDateToDaysRemaining(jsonOutput['result']['expirationDate']),
		helper.convertDateToDay(jsonOutput['result']['expirationDate']),
		helper.convertDateFormat(jsonOutput['result']['expirationDate'])))
	rows.append(["Days left", days])
	rows.append(["Status", jsonOutput['result']['status']])
	rows.append(["",""])
	
	rows.append(["ID", jsonOutput['result']['id']])
	rows.append(["Created Date", jsonOutput['result']['createdDate']])
	rows.append(["Edition", jsonOutput['result']['edition']])
	rows.append(["Dev Hub ID", jsonOutput['result']['devHubId']])
	rows.append(["Org Name", jsonOutput['result']['orgName']])
	rows.append(["Access Token", jsonOutput['result']['accessToken']])
	rows.append(["Instance Url", jsonOutput['result']['instanceUrl']])

	helper.createTable([], rows)

	helper.pressToContinue(True, None)


def deploy(mainMenu):
	subprocess.call([path + "deploy" + ext])
	helper.pressToContinue(True, None)


def login(mainMenu):
	helper.startLoading("Waiting for login in browser")
	error = helper.tryCommandWithException(["sfdx force:auth:web:login -d"], True, True)
	helper.pressToContinue(False, 10)