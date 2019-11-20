# -*- coding: utf-8 -*-
# encoding=utf8

import subprocess
import subscripts.helper as helper

def askUserForOrgs(lookingForRegularOrgs, mainMenu, text):
	root = "scratchOrgs"
	kind = "Scratch Orgs"
	
	if (lookingForRegularOrgs):
		root = "nonScratchOrgs"
		kind = "orgs"

	helper.startLoading("Loading {}".format(kind))
	orgs = subprocess.check_output(["sfdx", "force:org:list", "--json"])
	jsonOutput = helper.loadJson(orgs)
	helper.stopLoading()

	header = ['', 'Alias', 'Username', 'Org Id', 'Expiration Date', 'Default']
	rows = []

	number = 1

	for row in jsonOutput['result'][root]:
		
		alias = helper.ifKeyExists('alias', row)
		username = helper.ifKeyExists('username', row)
		orgId = helper.ifKeyExists('orgId', row)
		expirationDate = helper.ifKeyExists('expirationDate', row)
		defaultMarker = helper.ifKeyExists('defaultMarker', row).replace('(U)', 'X').replace('(D)', 'X')
		
		rows.append([number, alias, username, orgId, expirationDate, defaultMarker ])
		number += 1

	if (len(rows) == 0):
		print(helper.col("\nYou have no active {}!".format(kind), [helper.c.r]))
		helper.pressToContinue(True, 10)
		return

	print(helper.col("\nYou have the following {}:".format(kind), [helper.c.y]))

	helper.createTable(header, rows)

	print("\n" + text + helper.col(" [1-{}] (empty to exit)".format(len(rows)), [helper.c.y, helper.c.BOLD]))

	choice = helper.askForInputUntilEmptyOrValidNumber(len(rows))


	if (choice != -1):
		if (rows[choice][1]):
			return rows[choice][1]
		else:
			return rows[choice][2]
	else:
		return ""

import os
def fetchPermsets():
	try:
		permsets = helper.fetchFilesFromFolder("./force-app/main/default/permissionsets/", False)
		for i, permset in enumerate(permsets):
			permsets[i] = permset.replace(".permissionset-meta.xml", "")
		return permsets
	except Exception as e:
		helper.spinnerError()
		print(e)


from shutil import copyfile
from pathlib import Path
import shutil

def importDummyData():
	
	try:
		path = "./dummy-data/"
		copyfile("./scripts/config/unsignedPluginWhiteList.json", str(Path.home()) + "/.config/sfdx/unsignedPluginWhiteList.json")
		output = helper.runCommand("sfdx plugins:install sfdx-wry-plugin@0.0.9")
	
		for folder in next(os.walk(path))[1]:
			if (folder.endswith(".out")):
				shutil.rmtree(path + folder)

		for folder in next(os.walk(path))[1]:
			output = helper.runCommand('sfdx wry:file:replace -i {} -o {}'.format(path + folder, path + folder + ".out"))

		for folder in next(os.walk(path))[1]:
			if (folder.endswith(".out")):
				output = helper.runCommand('sfdx force:data:tree:import --plan {}{}/plan.json'.format(path, folder))

		helper.spinnerSuccess()
	except subprocess.CalledProcessError as e:
		helper.spinnerError()
		print("\n" + e.output.decode('UTF-8'))
		helper.pressToContinue(True, None)
		return True
	except Exception as e:
		helper.spinnerError()
		print(e)
		helper.pressToContinue(True, None)
		return True
	return False