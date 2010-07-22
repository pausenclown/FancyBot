@echo off
break off
if not exist bin\perl goto PERLNOTFOUND
if not exist bin\fancybot_webshell_server.pl goto SHELLNOTFOUND

SET PERL5LIB=bin\perl\lib;bin\perl\site\lib;bin\perl\vendor\lib
SET PATH=bin\perl\bin

goto RUN

:RUN
echo Starting WebShell...
start /B /WAIT bin\perl\bin\perl.exe bin\fancybot_webshell_server.pl

goto END

:PERLNOTFOUND
echo Perl was not found, You are probably in the wrong working directory.
goto END

:SHELLNOTFOUND
echo Webshell executable not found, You are probably in the wrong working directory.
goto END

:END
echo Webshell stopped.
pause>nul
