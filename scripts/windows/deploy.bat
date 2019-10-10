:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off
call cls

if "%cd:~-16%" == "\scripts\windows" (
	cd ..\..
)

echo.
set /p isInCorrectBranch="Are you in the correct branch to push code from? [y/n]: "
IF /I NOT "%isInCorrectBranch%"=="y" ( exit )

echo.
set /p isTestedInNewScratchOrg="Have you verified that all code works in a NEW scratch org? [y/n]: "
IF /I NOT "%isTestedInNewScratchOrg%"=="y" ( exit )

echo.
set /p isAllCodeTested="Have you verified that all tests are passing and have enough code coverage? [y/n]: "
IF /I NOT "%isAllCodeTested%"=="y" ( exit )

echo. & echo These are the available orgs to deploy to & echo --------------------------------------------
echo [Loading ... ] & echo.
call sfdx force:org:list

echo. & echo Enter the ALIAS or USERNAME of the org you want to deploy to (typically, you wouldn't deploy to a scratch org, FYI) & echo --------------------------------------------
set /p orgName="> "

:: converting source to medadata and creating a zip file
call sfdx force:source:convert --rootdir force-app --outputdir deployment_tmp
call jar -cfM deployment_tmp.zip deployment_tmp
call rmdir /q /s deployment_tmp

:: deploy to the org
call sfdx force:mdapi:deploy --zipfile deployment_tmp.zip --targetusername %orgName% --testlevel RunAllTestsInOrg -w 500

:: delete remaining files
call del deployment_tmp.zip

pause