@ECHO OFF & SETLOCAL ENABLEDELAYEDEXPANSION
:: Check php command
php --version >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO PHPUNIT

:: Try default php path
SET php_path=C:\php

:PHP_LOOP
:: Try to execute php
"%php_path%\php" --version >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO ADD_PHP

:: Ask for php path
SET /p php_path="Please enter path to php.exe: "
:: Remove any quotes from path
SET php_path=%php_path:"=%
:: Remove any backslash from path
IF %php_path:~-1% == \ SET php_path=%php_path:~0,-1%
GOTO PHP_LOOP

:ADD_PHP
:: Add php path to global path variable
ENDLOCAL & SET php_path=%php_path%
SET path=%path%;"%php_path%"
SETLOCAL ENABLEDELAYEDEXPANSION

:PHPUNIT
call phpunit >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO TYPO3
IF %ERRORLEVEL% == 2 GOTO TYPO3

: Try to find phpunit in current path
SET phpunit_path=%~dp0bin

:PHPUNIT_LOOP
:: Find phpunit executable
IF EXIST "%phpunit_path%\phpunit.bat" GOTO ADD_PHPUNIT

:: Ask for phpunit path
SET /p phpunit_path="Please enter path to phpunit.bat: "
:: Remove any quotes from path
SET phpunit_path=%phpunit_path:"=%
:: Remove any backslash from path
IF %phpunit_path:~-1% == \ SET phpunit_path=%phpunit_path:~0,-1%
GOTO PHPUNIT_LOOP

:ADD_PHPUNIT
:: Add phpunit path to global path variable
ENDLOCAL & SET phpunit_path=%phpunit_path%
SET path=%path%;"%phpunit_path%"
SETLOCAL ENABLEDELAYEDEXPANSION

:TYPO3
:: Find TYPO3 root
SET typo3_path=.

:TYPO3_LOOP
IF EXIST "%typo3_path%\typo3/sysext/core/Build/UnitTests.xml" GOTO UNITTESTS

:: Ask for TYPO3 path
SET /p typo3_path="Please enter path to TYPO3 root: "
:: Remove any quotes from path
SET typo3_path=%typo3_path:"=%
GOTO TYPO3_LOOP

:UNITTESTS
cd "%typo3_path%"
call phpunit.bat -c typo3/sysext/core/Build/UnitTests.xml
IF NOT %ERRORLEVEL% == 0 EXIT /b

:: If Ramdisk isn't found, don't execute the functional tests
IF NOT EXIST "H:\MySQL Server" EXIT /b

:: Check mysql access
netstat -ona | FINDSTR 3307 >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO FUNCTIONALTESTS

ECHO "Starting MySQL Server..."
::dir /B /S mysqld.exe
START /B CMD /C ""C:\Program Files\MySQL Server\bin\mysqld" --defaults-file="H:\MySQL Server\my-typo3ram.ini" --standalone"
:: Sleep for 10 seconds
ping -n 10 127.0.0.1 > NUL

:FUNCTIONALTESTS
set typo3DatabaseHost=127.0.0.1
set typo3DatabasePort=3307
set typo3DatabaseUsername=root
set typo3DatabasePassword=
set typo3DatabaseName=functional

:: Remove old test folders
FOR /D %%d IN ("typo3temp\functional-*") DO RMDIR /S /Q "%%d"

call phpunit.bat -c typo3/sysext/core/Build/FunctionalTests.xml