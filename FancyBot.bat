@echo off
if not exist bin\perl goto PERLNOTFOUND
if not exist bin\fancybot goto BOTNOTFOUND

SET PERL5LIB=bin\perl\lib;bin\perl\site\lib;bin\perl\vendor\lib
goto RUN

:CRASH
echo Bot crashed hard. Restarting.

:RUN
echo Starting executable...
bin\perl\bin\perl.exe bin\fancybot
if not exist stop_bot goto CRASH
del stop_bot
goto END

:PERLNOTFOUND
echo Perl was not found, You are probably in the wrong working directory.
goto END

:BOTNOTFOUND
echo Fancybot executable not found, You are probably in the wrong working directory.
goto END

:END
echo Fancybot stopped.
pause>nul
