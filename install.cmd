@echo off

:: Check for Python Installation
python --version 3>NUL
if errorlevel 1 goto errorNoPython

:: Reaching here means Python is installed.
call pip3 install virtualenv
RD /S /Q "%cd%\venv"
call mkdir venv
call virtualenv venv
call venv\Scripts\activate
call pip install -r scripts\python\requirements.txt

echo.
set /p tmp="Finished"


:: Once done, exit the batch file -- skips executing the errorNoPython section
goto:eof

:errorNoPython

call start https://www.python.org/ftp/python/3.8.0/python-3.8.0.exe
echo.
set /p tmp="Press enter after installing Python (REMEMBER TO CHECK 'ADD PYTHON 3.8 TO PATH')"

call start https://bootstrap.pypa.io/get-pip.py

echo.
echo Save get-pip.py to the root folder (%cd%)
set /p tmp="Press enter after saving at root"
call python get-pip.py
del get-pip.py