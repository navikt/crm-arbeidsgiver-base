@echo off
call cls

if "%cd:~-16%" == "\scripts\windows" (
	cd ..\..
)

call .\scripts\windows\sub-scripts\createBranch.bat
call .\scripts\windows\sub-scripts\createScratchOrg.bat
call .\scripts\windows\sub-scripts\pushAllMetadata.bat
call .\scripts\windows\sub-scripts\openScratchOrg.bat
call .\scripts\windows\sub-scripts\importPermSets.bat
call .\scripts\windows\sub-scripts\importDummyData.bat
call .\scripts\windows\sub-scripts\runCustomApex.bat

pause