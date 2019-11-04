from consolemenu import *
from consolemenu.items import *
import os

menu = ConsoleMenu("Salesforce DX CLI Helper", "Choose an option:")
path = ""
ext = ""


def definePathAndExtension():
    global path
    global ext

    if (os.name == "posix"):
        path = "scripts/mac/"
        ext = ".command"
    else:
        path = "scripts\windows\\"
        ext = ".cmd"


def createMenu():
    global path
    global ext

    createScratchOrg = CommandItem(
        "Create scratch org", path + "createScratchOrg" + ext)
    deploy = CommandItem(
        "Deploy to an org (production, sandbox only)", path + "deploy" + ext)
    login = CommandItem("Login to a production org", path + "login" + ext)
    openScratchOrg = CommandItem(
        "Open your default scratch org", path + "openScratchOrg" + ext)
    pull = CommandItem(
        "Pull changes from your active Salesforce Scratch Org", path + "pull" + ext)
    push = CommandItem(
        "Push changes to your active Salesforce Scratch Org", path + "push" + ext)

    menu.append_item(createScratchOrg)
    menu.append_item(deploy)
    menu.append_item(login)
    menu.append_item(openScratchOrg)
    menu.append_item(pull)
    menu.append_item(push)


def init():
    definePathAndExtension()
    createMenu()


def main():
    menu.show()


init()
main()
