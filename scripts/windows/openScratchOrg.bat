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

call sfdx force:org:open

pause