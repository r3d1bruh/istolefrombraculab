@echo off

:START
FOR /f "tokens=*" %%a IN ('dir c:\USERS /b /ad') DO CALL :PATHCHECK "%%a"
GOTO REGISTRY

::The following is where you would put in the profile you wish to exclude from the wipe. Just copy/paste a line and make the appropriate revisions.

:PATHCHECK
IF /i [%1]==["Administrator"] GOTO :PATHSKIP
IF /i [%1]==["All Users"] GOTO :PATHSKIP
IF /i [%1]==["Default"] GOTO :PATHSKIP
IF /i [%1]==["Default user"] GOTO :PATHSKIP
IF /i [%1]==["public"] GOTO :PATHSKIP
GOTO PATHCLEAN

:PATHSKIP
ECHO. Skipping path clean for user %1
GOTO :EOF

:PATHCLEAN
ECHO. Cleaning profile for: %1
rmdir C:\USERS\%1 /s /q > NUL
IF EXIST "C:\USERS\%1" GOTO RETRYPATHFIRST
IF NOT EXIST "C:\USERS\%1" GOTO :EOF

:RETRYPATHFIRST
ECHO. Error cleaning profile for: %1 - Trying again.
rmdir C:\USERS\%1 /s /q > NUL
IF EXIST "C:\USERS\%1" GOTO RETRYPATHSECOND
IF NOT EXIST "C:\USERS\%1" GOTO :EOF

:RETRYPATHSECOND
ECHO. Error cleaning profile for: %1 - Trying again.
rmdir C:\USERS\%1 /s /q > NUL
GOTO :EOF

:REGISTRY
ECHO.------------
FOR /f "tokens=*" %%a IN ('reg query "hklm\software\microsoft\windows nt\currentversion\profilelist"^|find /i "s-1-5-21"') DO CALL :REGCHECK "%%a"
GOTO VERIFY

::The following is where it parses the registry data and checks it against the user path. Copy/paste the IF line and make the user modification needed.

:REGCHECK
FOR /f "tokens=3" %%b in ('reg query %1 /v ProfileImagePath') DO SET USERREG=%%b
IF /i [%USERREG%]==[c:\Users\Administrator] GOTO :REGSKIP
GOTO REGCLEAN

:REGSKIP
ECHO. Skipping registry clean for %USERREG%
GOTO :EOF

:REGCLEAN
ECHO. Cleaning registry for: %USERREG%
reg delete %1 /f
GOTO :EOF

::The cleaning portion of the script is now done. Now begins the verification and log reporting.

:VERIFY
FOR /f "tokens=*" %%c IN ('dir c:\USERS /b /ad') DO CALL :VERIFYPATH "%%c"

::Same thing as the clean - if you need to exclude an account, make your copy/paste below.

:VERIFYPATH
IF /i [%1]==["Administrator"] GOTO :EOF
IF /i [%1]==["All Users"] GOTO :EOF
IF /i [%1]==["Default"] GOTO :EOF
IF /i [%1]==["Default user"] GOTO :EOF
IF /i [%1]==["public"] GOTO :EOF
GOTO VERPATHREPORT

:VERPATHREPORT
ECHO. %1
IF /i [%1]==[] (
set PATHRESULT=PATH_SUCCESS
) ELSE (
set PATHRESULT=PATH_FAILURE
)
ECHO. %PATHRESULT%
GOTO REGVERIFY

:REGVERIFY
ECHO.------------
FOR /f "tokens=*" %%d IN ('reg query "hklm\software\microsoft\windows nt\currentversion\profilelist"^|find /i "s-1-5-21"') DO CALL :REGCHECKVERIFY "%%d"
GOTO REGVERIFYECHO

::Same thing as the registry clean - copy/paste excluded profiles below.

:REGCHECKVERIFY
FOR /f "tokens=3" %%e in ('reg query %1 /v ProfileImagePath') DO SET USERREGV=%%e
IF /i [%USERREGV%]==[c:\Users\Administrator] GOTO :EOF
GOTO REGVERIFYECHO

:REGVERIFYECHO
ECHO. %1
IF /i [%1]==[] (
set REGRESULT=REG_SUCCESS
) ELSE (
set REGRESULT=REG_FAILURE
)
ECHO. %REGRESULT%
GOTO REPORTCHECK

::The following is where you would enter the mapped drive path.
::You can use a straight UNC if you like, but I find this to be a bit
::more solid and it allows you to use different creds in case you
::automate it for a local scheduled task to run as local admin.

:REPORTCHECK
net use t: \\server\path

IF EXIST "t:\labreport.txt" (
GOTO REPORTGEN
) ELSE (
GOTO EXIT
)

::This is a time/date stamp creator that I actually pulled from a Minecraft
::to Dropbox backup script I made a long while back.

:REPORTGEN
FOR /F "tokens=1 delims=:" %%f in ('time /T') DO SET T=%%f
FOR /F "tokens=*" %%g in ('echo %date:~10,4%-%date:~4,2%-%date:~7,2% %T%-%time:~3,2%-%time:~6,2%') DO SET TDATETIME=%%g

ECHO. %PATHRESULT% %REGRESULT% %COMPUTERNAME% %TDATETIME% >> "t:\labreport.txt"
net use t: /delete
GOTO EXIT

:EXIT
exit

:EOF