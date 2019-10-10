:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: push code to search
echo. & echo %yellow%Pushing all code to Scratch Org ... & echo.----------------------------------------------%default%
call sfdx force:source:push