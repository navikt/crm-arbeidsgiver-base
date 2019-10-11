# How to initialize an new scratch org

## Start the scripts

1. Open the terminal i VS Code (`Ctrl+Ø`)
2. Type the following:
	* For Windows: `.\init-scripts\windows.bat`
	* For Mac/Linux: `sh init-scripts/unix.sh`

## What the scripts do

The script does the following:
* Creates a new scratch org
* Pushes all code to it
* Adds all permissions sets that exists in `force-app\main\default\permissionsets\`
* Imports all dummy data PLANS from the `dummy-data` folder
* Opens the Scratch Org in your default browser

## How to copy this to other projects

1. Copy the entire `init-scripts` folder to the root folder of your new project
2. Create an empty `dummy-data` folder in your root folder
3. Copy `dummy-data\README.md` to the new `dummy-data` folder
3. Create dummy data as necessary (see `dummy-data\README.md`)