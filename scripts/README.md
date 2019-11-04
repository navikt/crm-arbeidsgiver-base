# SFDX scripts

Assortment of scripts to aid a Salesforce developer.

## Start the scripts

1. Open the terminal in VS Code (`Ctrl + Ø` / `Shift + ^ + ´`) or WebStorm (`Alt + F12` / `⌥ + F12`) 
2. Type the following:
	* For Windows: `scripts\windows\*.bat`
	* For Mac/Linux: `scripts/mac/*.command`

## What the scripts do

The script does the following:
* createScratchOrg
  * Asks if you want a new branch
  * Creates a new scratch org
  * Pushes all code and metadata to it
  * Adds all permissions sets that exists in `force-app\main\default\permissionsets\` and assigns it to your Scratch Org admin user
  * Imports all dummy data PLANS from the `dummy-data` folder
  * Opens the Scratch Org in your default browser
* deploy
  * gives you your list of orgs and which to deploy to 
* login
  * login in to a Dev Hub and set in as the default for this project
* pull
  * force pull changes from your Scratch Org