# -*- coding: utf-8 -*-
# encoding=utf8

import os
from consolemenu import *
import subscripts.menu as menu
import subscripts.helper as helper

mainMenu = None

def init():
	global mainMenu
	mainMenu = menu.createMenu(mainMenu)
	helper.updateMenuInformation(mainMenu)
	menu.createMenuItems(mainMenu)

def main():
	mainMenu.show()
	mainMenu.join()

init()
main()