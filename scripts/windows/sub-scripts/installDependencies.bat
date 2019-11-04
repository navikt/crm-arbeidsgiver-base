:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: push code to search
echo. & echo %yellow%Installing packages ... & echo.----------------------------------------------%default%
call sfdx force:package:install -w 10 -b 10 -r -p 04t2o000001Mx1PAAS