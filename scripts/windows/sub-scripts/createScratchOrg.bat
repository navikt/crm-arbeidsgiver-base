:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off
echo.
set /p id="%yellow%Enter Scratch Org name (non-unique names replaces old ones): %default%"

:: delete old scratch org
echo.
set /p deleteScratchOrg="%yellow%Do you wanna delete the old scratch org? %red%(NOTE! The currently active org will NOT be recoverable) %yellow%[y/n]: %default%"
IF /I "%deleteScratchOrg%"=="y" ( echo. & echo %yellow%Deleting the previous scratch org ... & echo.----------------------------------------------%default% )
IF /I "%deleteScratchOrg%"=="y" ( call sfdx force:org:delete -p )

:: creating scratch org
echo. & echo %yellow%Creating Scratch Org ... & echo.----------------------------------------------%default%
call sfdx force:org:create -f .\config\project-scratch-def.json --setalias %id% --durationdays 5 --setdefaultusername

SETLOCAL ENABLEDELAYEDEXPANSION
:: finding instance row to get instance location
FOR /F "tokens=* USEBACKQ" %%F IN (`sfdx force:org:display`) DO ( SET org=%%F & if /i "!org:~0,8!"=="Instance" goto :while )
:while
set "org=%org: =%"
if not x%org:cs89.my.salesforce.com=%==x%org% (
	echo inside
	echo. & echo %red%Deleting previous Scratch Org, as previous was cs89 instance, which contains bugs & echo.----------------------------------------------%default%
	call sfdx force:org:delete -p
	echo. & echo %yellow%Creating new Scratch Org, as previous was cs89 instance & echo.----------------------------------------------%default%
	call sfdx force:org:create -f .\config\project-scratch-def.json --setalias %id% --durationdays 5 --setdefaultusername
	FOR /F "tokens=* USEBACKQ" %%F IN (`sfdx force:org:display`) DO ( SET org=%%F & if /i "!org:~0,8!"=="Instance" goto :while )
)
ENDLOCAL