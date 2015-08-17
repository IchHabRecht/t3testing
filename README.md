# t3testing #
Simple script to execute unit and functional tests for TYPO3 CMS on Windows systems.

## Usage ##

`t3testing.bat`

The script ask you to enter several path information (e.g. path to PHP or PHPUnit if not found) or you can set options as arguments.

## Options ##

`--php_path=path`
Path to PHP executable. Default "C:\php"

`--phpunit_path=path`
Path to phpunit.bat file from composer installation. Default ".\bin"

`--mysql_path=path`
Path to mysqld.exe file for MySQL Server. If not set, script tries to locate it on its own

`--mysql_defaults_file=file_name`
Path to my.ini file with the MySQL Server configuration

`--mysql_host=addr`
Address where MySQL Server is listening. Default 127.0.0.1

`--mysql_port=port_num`
Port number where MySQL Server is listening. Default 3306

`--mysql_user=user_name`
User to connect to MySQL Server. Default "root"

`--mysql_password=password`
Password for user to connect to MySQL Server. Default ^<empty^>

`--mysql_database=prefix`
Prefix for databases created for functional tests. Default "functional"

`--typo3_path=path`
Path to TYPO3 root Default ".\"

Furthermore you can add PHPUnit command-line test runner's options. See https://phpunit.de/manual/current/en/textui.html#textui.clioptions
