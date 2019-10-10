:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: run apex code
echo. & echo %yellow%Running apex code from .\scripts\apex\ ... & echo.----------------------------------------------%default%
for %%f in (scripts\apex\*.cls) do echo %yellow%Running .\scripts\apex\%%~nxf%default% & call sfdx force:apex:execute --apexcodefile .\scripts\apex\%%~nxf