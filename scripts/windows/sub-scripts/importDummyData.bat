:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: Installing plugins
echo. & echo %yellow%Installing plugins needed for running script ... & echo.----------------------------------------------%default%
if not exist "%LOCALAPPDATA%\sfdx" mkdir %LOCALAPPDATA%\sfdx
call xcopy /Y .\config\unsignedPluginWhiteList.json %LOCALAPPDATA%\sfdx\
call sfdx plugins:install sfdx-wry-plugin@0.0.9

:: converting record types to the current org record type ID
echo. & echo %yellow%Converting record types to the current org record type ID ... & echo.----------------------------------------------%default%
for /D %%f in (.\dummy-data\*.out) do call RD /S /Q "%%f"
for /D %%f in (.\dummy-data\*) do call sfdx wry:file:replace -i "%%f" -o "%%f.out"

:: adding all dummy data plans
echo. & echo %yellow%Importing dummy data ... & echo.----------------------------------------------%default%
for /D %%f in (.\dummy-data\*.out) do call sfdx force:data:tree:import --plan "%%f\plan.json"