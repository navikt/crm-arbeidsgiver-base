# -*- coding: utf-8 -*-
# encoding=utf8

import subprocess, os, json
import subscripts.helper as helper

def pull(mainMenu):
	pushOrPull(mainMenu, "pull", False)

def push(mainMenu):
	pushOrPull(mainMenu, "push", False)

def pushOrPullException(mainMenu, value, isForce):
	print(helper.col("\nWould you like to {} using the --forceoverwrite flag?".format(value), [helper.c.y, helper.c.UL]) + " [y/n]")
	print(helper.col("(This will overwrite the metadata if it has been changed in both locations)", [helper.c.r]))
	val = input(" > ")
	if (val == "y"):
		helper.clear()
		pushOrPull(mainMenu, value, True)

def pushOrPull(mainMenu, value, isForce):

	force = ""
	forceText = ""
	if (isForce):
		force = "-f"
		forceText = " with force"

	helper.startLoading("{}ing Metadata{}".format(value, forceText))

	try:
		output = subprocess.check_output("sfdx force:source:{} {}".format(value, force), shell=True, stderr=subprocess.STDOUT)
		helper.spinnerSuccess()	
		helper.pressToContinue(False, 20)
	except subprocess.CalledProcessError as e:
		
		helper.spinnerError()
		print("Oopsie, an error occured when {}ing metadata!\n\n".format(value))
		print(e.output.decode('UTF-8'))

		if (not isForce):
			pushOrPullException(mainMenu, value, isForce)
		else:
			helper.pressToContinue(True, 20)
	