
@echo OFF

rem Set parameters
set ORG_ALIAS=arbeidsgiver-base


@echo:
echo Installing crm-arbeidsgiver-base scratch org (%ORG_ALIAS%)
@echo:

echo Cleaning previous scratch org...
cmd.exe /c sfdx force:org:delete -p -u %ORG_ALIAS% 2>NUL
@echo:

echo Creating scratch org...
cmd.exe /c sfdx force:org:create -s -f config/project-scratch-def.json -d 7 -a %ORG_ALIAS%
call :checkForError
@echo:

echo Installing dependencies...
for /f "tokens=1,2 delims=:{} " %%A in (env.json) do set secret=%%~A

echo "Installing crm-platform-base ver. 0.168"
call sfdx force:package:install --package 04t7U000000Tq8fQAC -r -k %secret% --wait 10 --publishwait 10

echo "Installing crm-platform-integration ver. 0.82"
call sfdx force:package:install --package 04t7U000000Tq94QAC -r -k %secret% --wait 10 --publishwait 10

echo "Installing crm-platform-access-control ver. 0.102"
call sfdx force:package:install --package 04t7U000000Tq8LQAS -r -k %secret% --wait 10 --publishwait 10

echo "Installing crm-shared-base ver. 1.1"
call sfdx force:package:install --package 04t2o000000ySqpAAE -r -k %secret% --wait 10 --publishwait 10

echo "Installing crm-shared-timeline ver. 1.15"
call sfdx force:package:install --package 04t7U000000TpOcQAK -r -k %secret% --wait 10 --publishwait 10

echo Pushing metadata...
cmd.exe /c sfdx force:source:push
call :checkForError
@echo:

echo Pushing unpackaged data...
cmd.exe /c sfdx force:source:deploy -p ./unpackagable
call :checkForError
@echo:

echo Assigning permissions...
cmd.exe /c sfdx force:user:permset:assign -n Create_reports_and_dashboards
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_WarningWrite
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_Create_and_share_reportfolders
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_Kampanje
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_NavApp
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_NavTask
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_Sykefravaer
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_arenaActivity
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_base
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_contract
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_opportunity
cmd.exe /c sfdx force:user:permset:assign -n Arbeidsgiver_temporaryLayoffs
cmd.exe /c sfdx force:user:permset:assign -n CRM_LoginFlow
call :checkForError
@echo:

echo Inserting test data...
cmd.exe /c sfdx force:data:tree:import -p  dummy-data/activityTimeline/plan.json
cmd.exe /c sfdx force:data:tree:import -p  dummy-data/tag/plan.json
call :checkForError
@echo:

echo Opening org...
cmd.exe /c sfdx force:org:open
@echo:

rem Report install success if no error
@echo:
if ["%errorlevel%"]==["0"] (
  echo Installation completed.
  @echo:
)

:: ======== FN ======
GOTO :EOF

rem Display error if the install has failed
:checkForError
if NOT ["%errorlevel%"]==["0"] (
    echo Installation failed.
    exit /b %errorlevel%
)
