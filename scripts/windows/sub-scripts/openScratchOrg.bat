:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: opening scratch org
echo. & echo %yellow%Opening Scratch Org ... & echo.----------------------------------------------%default%
call sfdx force:org:open