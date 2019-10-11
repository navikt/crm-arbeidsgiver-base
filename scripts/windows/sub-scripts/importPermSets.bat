:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: adding all permission sets
echo. & echo %yellow%Adding permission sets ... & echo.----------------------------------------------%default%
setlocal enabledelayedexpansion
set FOLDER_PATH=force-app\main\default\permissionsets\
for %%f in (%FOLDER_PATH%*) do if %%f neq %~nx0 (
	set "filename=%%~nf"
	call sfdx force:user:permset:assign -n !filename:~0,-19!
)