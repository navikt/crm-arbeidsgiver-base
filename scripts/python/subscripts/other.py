# -*- coding: utf-8 -*-
# encoding=utf8

import subscripts.helper as helper

def createPackageKey(mainMenu):
	
	packageKey = helper.askForInput( [ ["Enter the password needed to install packages", [ helper.c.y ]] ] )
	
	try:
		f = open(".packageKey", "w")
	except IOError:
		f = open(".packageKey", "x")
	finally:
		f.write(packageKey)
		f.close()
		print(helper.col("\nSuccessfully added key to .packageKey", [helper.c.y, helper.c.UL]))
		helper.pressToContinue(False, 10)

