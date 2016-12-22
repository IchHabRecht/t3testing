@ECHO OFF & SETLOCAL

:: Initialize variables
SET default_php_path=C:\php
SET php_path=
SET default_phpunit_path=%~dp0bin
SET phpunit_path=
SET typo3_path=.
SET mysql_path=
SET mysql_defaults_file=
SET mysql_host=127.0.0.1
SET mysql_port=3306
SET mysql_user=root
SET mysql_password=
SET mysql_database=functional
SET phpunit_arguments=
SET server_name=

:ARGUMENT_LOOP
IF NOT "%1" == "" (
	IF /I [%1] == [--php_path] (
		SET php_path=%2
		SHIFT
		SET i=0
	) ELSE (
		IF /I [%1] == [--phpunit_path] (
			SET phpunit_path=%2
			SHIFT
			SET i=0
		) ELSE (
			IF /I [%1] == [--mysql_path] (
				SET mysql_path=%2
				SHIFT
				SET i=0
			) ELSE (
				IF /I [%1] == [--mysql_defaults_file] (
					SET mysql_defaults_file=%2
					SHIFT
					SET i=0
				) ELSE (
					IF /I [%1] == [--mysql_host] (
						SET mysql_host=%2
						SHIFT
						SET i=0
					) ELSE (
						IF /I [%1] == [--mysql_port] (
							SET mysql_port=%2
							SHIFT
							SET i=0
						) ELSE (
							IF /I [%1] == [--mysql_user] (
								SET mysql_user=%2
								SHIFT
								SET i=0
								) ELSE (
								IF /I [%1] == [--mysql_password] (
									SET mysql_password=%2
									SHIFT
									SET i=0
								) ELSE (
									IF /I [%1] == [--mysql_database] (
										SET mysql_database=%2
										SHIFT
										SET i=0
									) ELSE (
										IF /I [%1] == [--typo3_path] (
											SET typo3_path=%2
											SHIFT
											SET i=0
										) ELSE (
											IF /I [%1] == [--server_name] (
												SET server_name=%2
												SHIFT
												SET i=0
											) ELSE (
												IF /I [%1] == [/?] (
													GOTO USAGE
												) ELSE (
													SET phpunit_arguments=%phpunit_arguments% %1
												)
											)
										)
									)
								)
							)
						)
					)
				)
			)
		)
	)
	SHIFT

	GOTO ARGUMENT_LOOP
)

IF NOT [%server_name%] == [] SET PHP_IDE_CONFIG=serverName=%server_name%

IF NOT [%php_path%] == [] GOTO PHP_LOOP

:: Check php command
php --version >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO PHPUNIT
SET php_path=%default_php_path%

:PHP_LOOP
:: Remove any quotes from path
SET php_path=%php_path:"=%
:: Remove any backslash from path
IF %php_path:~-1% == \ SET php_path=%php_path:~0,-1%
:: Try to execute php
"%php_path%\php" --version >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO ADD_PHP

:: Ask for php path
SET /P php_path="Please enter path to php.exe: "
GOTO PHP_LOOP

:ADD_PHP
:: Add php path to global path variable
SET path="%php_path%";%path%
php --version
ECHO PHP found in "%php_path%" ...

:PHPUNIT
IF NOT [%phpunit_path%] == [] GOTO PHPUNIT_LOOP

CALL phpunit.bat >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO TYPO3_LOOP
IF %ERRORLEVEL% == 2 GOTO TYPO3_LOOP
SET phpunit_path=%default_phpunit_path%

:PHPUNIT_LOOP
:: Remove any quotes from path
SET phpunit_path=%phpunit_path:"=%
:: Remove any backslash from path
IF %phpunit_path:~-1% == \ SET phpunit_path=%phpunit_path:~0,-1%
:: Find phpunit executable
IF EXIST "%phpunit_path%\phpunit.bat" GOTO ADD_PHPUNIT

:: Ask for phpunit path
SET /P phpunit_path="Please enter path to phpunit.bat: "
GOTO PHPUNIT_LOOP

:ADD_PHPUNIT
:: Add phpunit path to global path variable
SET path="%phpunit_path%";%path%
ECHO PHPUnit found in "%phpunit_path%" ...

:TYPO3_LOOP
:: Remove any quotes from path
SET typo3_path=%typo3_path:"=%
:: Remove any backslash from path
IF %typo3_path:~-1% == \ SET typo3_path=%typo3_path:~0,-1%
IF EXIST "%typo3_path%\typo3\sysext\core\Build\UnitTests.xml" GOTO UNITTESTS

:: Ask for TYPO3 path
SET /P typo3_path="Please enter path to TYPO3 root: "
GOTO TYPO3_LOOP

:UNITTESTS
CD /D "%typo3_path%"
:: Delete existing Cache folder
IF EXIST "typo3temp\Cache" RMDIR /S /Q "typo3temp\Cache"
IF EXIST "typo3temp\var\Cache" RMDIR /S /Q "typo3temp\var\Cache"
CALL phpunit.bat -c typo3/sysext/core/Build/UnitTests.xml %phpunit_arguments%
IF NOT %ERRORLEVEL% == 0 EXIT /B

:: Check MySQL access
IF [%mysql_defaults_file%] == [] GOTO CHECK_MYSQL_PORT
IF NOT EXIST %mysql_defaults_file% (
	ECHO mysql_defaults_file %mysql_defaults_file% not found
	GOTO EOF
)

:CHECK_MYSQL_PORT
:: Look for an existing connection on port
SET pid=
FOR /F "tokens=5" %%p IN ('NETSTAT -ona ^| FINDSTR %mysql_port%') DO (
	IF NOT %%p == 0 SET pid=%%p
)
IF NOT "%pid%" == "" GOTO FUNCTIONALTESTS

:MYSQL_LOOP
:: Remove any quotes from path
SET mysql_path=%mysql_path:"=%
:: Remove any backslash from path
IF NOT %mysql_path:~-1% == \ SET mysql_path=%mysql_path%\
:: Find mysql executable
IF EXIST "%mysql_path%\mysqld.exe" GOTO START_MYSQL

:: Find mysqld.exe and start MySQL Server
ECHO Trying to find MySQL Server ...
FOR /F "skip=1 delims=" %%x in ('wmic logicaldisk get caption') DO (
	PUSHD %%x
	FOR /F "tokens=*" %%a IN ('dir /B /S mysqld.exe') DO (
		SET mysql_path=%%a
		GOTO START_MYSQL
	)
	POPD
)
ECHO MySQL Server not running and no executable found. Please start MySQL Server on your own and restart tests
GOTO EOF

:START_MYSQL
SET mysql_path=%mysql_path:mysqld.exe=%
IF NOT [%mysql_defaults_file%] == [] (
	SET mysql_defaults_file=--defaults-file=%mysql_defaults_file%
)
IF NOT "%mysql_path%" == "" (
	ECHO Starting MySQL Server in "%mysql_path%" ...
	START /B CMD /C ""%mysql_path%mysqld.exe" %mysql_defaults_file% --standalone"
	:: Sleep for 10 seconds
	PING -n 10 127.0.0.1 >nul
)
POPD

:FUNCTIONALTESTS
SET typo3DatabaseHost=%mysql_host%
SET typo3DatabasePort=%mysql_port%
SET typo3DatabaseUsername=%mysql_user%
SET typo3DatabasePassword=%mysql_password%
SET typo3DatabaseName=%mysql_database%

:: Remove old test folders
FOR /D %%d IN ("typo3temp\functional-*") DO RMDIR /S /Q "%%d"
IF EXIST "typo3temp\tests" RMDIR /S /Q "typo3temp\tests"

CALL phpunit.bat -c typo3/sysext/core/Build/FunctionalTests.xml %phpunit_arguments%

IF NOT "%mysql_path%" == "" (
	ECHO "Stopping MySQL Server ...
	START /B CMD /C ""%mysql_path%mysqladmin.exe" -u %mysql_user% --password="%mysql_password%" --port=%mysql_port% shutdown"
)
GOTO EOF

:USAGE
ECHO Usage: t3testing.bat [options...] [phpunit options...]
ECHO.
ECHO Options:
ECHO --php_path=path                   Path to PHP executable. Default "C:\php"
ECHO --phpunit_path=path               Path to phpunit.bat file from composer installation. Default ".\bin"
ECHO --mysql_path=path                 Path to mysqld.exe file for MySQL Server. If not set, script tries to locate it on its own
ECHO --mysql_defaults_file=file_name   Path to my.ini file with the MySQL Server configuration
ECHO --mysql_host=addr                 Address where MySQL Server is listening. Default 127.0.0.1
ECHO --mysql_port=port_num             Port number where MySQL Server is listening. Default 3306
ECHO --mysql_user=user_name            User to connect to MySQL Server. Default "root"
ECHO --mysql_password=password         Password for user to connect to MySQL Server. Default ^<empty^>
ECHO --mysql_database=prefix           Prefix for databases created for functional tests. Default "functional"
ECHO --server_name=server_name         Set server name for PHP_IDE_CONFIG environment variable
ECHO --typo3_path=path                 Path to TYPO3 root Default ".\"
ECHO.
ECHO For PHPUnit command-line test runner's options see https://phpunit.de/manual/current/en/textui.html#textui.clioptions

:EOF
EXIT /B
