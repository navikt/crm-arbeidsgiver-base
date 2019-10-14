:: colors
set red=[31m
set yellow=[33m
set default=[39m

:: init
@echo off

:: asking user if they want to create a new branch
echo. & echo %red%REMEMBER TO REMOVE OR COMMIT ANY WOKRING FILES IF CREATING A NEW BRANCH!%default%
echo. & echo %red%REMEMBER TO REMOVE OR COMMIT ANY WOKRING FILES IF CREATING A NEW BRANCH!%default%
echo. & echo %red%REMEMBER TO REMOVE OR COMMIT ANY WOKRING FILES IF CREATING A NEW BRANCH!%default%
echo. & echo %red%REMEMBER TO REMOVE OR COMMIT ANY WOKRING FILES IF CREATING A NEW BRANCH!%default%
echo. & echo %yellow%----------------------------------------------%default%
echo. & echo %yellow%Would you like a new branch?%default%
echo. & echo %red%If NO, press enter without any text%default%
echo. & echo %yellow%If YES, type your branch name%default%

set /p branch="> "
IF /I NOT "%branch%"=="" (

	:: creating branch
	echo. & echo %yellow%Creating a new branch ... & echo.----------------------------------------------%default%
	call git checkout UAT
    call git pull
    call git checkout -b SF-%branch% master
	call git push origin SF-%branch%
)