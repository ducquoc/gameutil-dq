@ECHO OFF

SET REG_AOK_KEY="HKLM\SOFTWARE\Microsoft\DirectPlay\Applications\Age of Empires II"
SET REG_AOC_KEY="HKLM\SOFTWARE\Microsoft\DirectPlay\Applications\Age of Empires II - The Conquerors Expansion"
SET REG_PATH_VALUE=Path

SET INTERFAC_DRS=interfac.drs
SET EMPIRES2_EXE=Empires2.exe
SET SLPLIST_FILE=slplist.txt

SET EMPIRES2_EXE_SIZE=2555904

SET ERROR0=ERROR: Java seems to be not installed on your computer. Download and install JRE from http://www.oracle.com/technetwork/java/javase/downloads/index.html. If you have JRE installed and you still see this message, add java to your PATH variable. See http://docs.oracle.com/javase/tutorial/essential/environment/paths.html
SET ERROR1=ERROR: Game installation nor %INTERFAC_DRS% found, copy %INTERFAC_DRS% to this directory and launch script again.
SET ERROR2=ERROR: Game installation nor %EMPIRES2_EXE% found, copy %EMPIRES2_EXE% to this directory and launch script again.
SET ERROR5=ERROR: Widescreen patch is not supported for your version of AOK executable %EMPIRES2_EXE% file. Download supported executable from http://code.google.com/p/aoe2wspatch/downloads/list and copy it to this directory.

FOR /F "tokens=2,*" %%a IN ('REG QUERY %REG_AOK_KEY% /v %REG_PATH_VALUE% 2^>nul') DO SET AOK_PATH=%%b
FOR /F "tokens=2,*" %%a IN ('REG QUERY %REG_AOC_KEY% /v %REG_PATH_VALUE% 2^>nul') DO SET AOC_PATH=%%b

IF NOT DEFINED AOC_PATH (
  SET REG_AOC_KEY="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\DirectPlay\Applications\Age of Empires II - The Conquerors Expansion"
  FOR /F "tokens=2,*" %%a IN ('REG QUERY %REG_AOC_KEY% /v %REG_PATH_VALUE% 2^>nul') DO SET AOC_PATH=%%b
)

IF NOT DEFINED AOC_PATH (
  SET REG_AOC_KEY="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameUX\S-1-5-21-1343024091-879983540-725345543-1744000\{8773BD18-0B94-4516-9CAE-09A6A3F0A27C}"
  SET REG_PATH_VALUE=ConfigApplicationPath
  FOR /F "tokens=2,*" %%a IN ('REG QUERY %REG_AOC_KEY% /v %REG_PATH_VALUE% 2^>nul') DO SET AOC_PATH=%%b
)

IF NOT DEFINED AOK_PATH (
  SET AOK_PATH=%AOC_PATH%\..
) ELSE (
  if "%AOK_PATH%"=="%AOC_PATH%" SET AOK_PATH=%AOC_PATH%\..
)
echo AOK_PATH is: %AOK_PATH%

::check if we have java installed
java -version 2> jv.txt
SET /P JV=<jv.txt
IF /I NOT "%JV:~0,12%" == "java version" GOTO error0

::check for required files
:drscheck
IF NOT EXIST %INTERFAC_DRS% GOTO getdrs
ECHO %INTERFAC_DRS% found in current directory. Using it...
:aokcheck
IF NOT EXIST %EMPIRES2_EXE% GOTO getaok
ECHO %EMPIRES2_EXE% found in current directory. Using it...
GOTO process

:getdrs
IF NOT DEFINED AOK_PATH GOTO error1
IF NOT EXIST "%AOK_PATH%\Data\%INTERFAC_DRS%" GOTO error1
ECHO %INTERFAC_DRS% found in %AOK_PATH%\Data\ directory. Copying...
COPY "%AOK_PATH%\Data\%INTERFAC_DRS%" %INTERFAC_DRS%
GOTO aokcheck

:getaok
IF NOT DEFINED AOK_PATH GOTO error2
IF NOT EXIST "%AOK_PATH%\%EMPIRES2_EXE%" GOTO error2
ECHO %EMPIRES2_EXE% found in %AOK_PATH%\ directory. Copying...
COPY "%AOK_PATH%\%EMPIRES2_EXE%" %EMPIRES2_EXE%

GOTO process


:process
:: check if we have supported executables
SET AOK_SIZE=0
IF EXIST %EMPIRES2_EXE% FOR /F "usebackq" %%A IN ('%EMPIRES2_EXE%') DO SET AOK_SIZE=%%~zA

IF EXIST %EMPIRES2_EXE% IF NOT %AOK_SIZE% == %EMPIRES2_EXE_SIZE% GOTO error5

::patch executables
patcher %EMPIRES2_EXE% aok20a_offsets

::patch interfac.drs
FOR /F %%i IN (%SLPLIST_FILE%) DO drsbuild /e %INTERFAC_DRS% %%i
java -jar slpreadermain.jar
DEL *.slp
resizeframes
REM java -jar slpwritermain.jar
FOR %%i IN (int*.bmp) DO bmp2slp %%i
DEL int*.bmp
DEL mask.bmp
FOR /F %%i IN (%SLPLIST_FILE%) DO IF EXIST %%i drsbuild /r %INTERFAC_DRS% %%i
DEL *.slp
FOR %%i IN (*.ws) DO SET INTERFAC_WS=%%i
DEL %INTERFAC_WS%
RENAME %INTERFAC_DRS% %INTERFAC_WS%
IF NOT EXIST "%AOK_PATH%" GOTO msg0
IF NOT EXIST "%AOK_PATH%\Data\" GOTO msg0
IF EXIST age2_x1_*.exe IF NOT EXIST "%AOC_PATH%" GOTO msg0
ECHO Moving patched files to AOE2 installation directory...
MOVE Empires2_*.exe "%AOK_PATH%"
MOVE %INTERFAC_WS% "%AOK_PATH%\Data\"
REM IF EXIST age2_x1_*.exe MOVE age2_x1_*.exe "%AOC_PATH%"

ECHO DONE.
ECHO You should find new executables in you aoe2 installation directory. To use widescreen launch generated executables and set the game's screen size to 1024x768 in game options.
GOTO finish

:msg0
ECHO DONE.
ECHO Copy generated executable files to aoe2 installation directory and generated .ws file to \Data directory. To use widescreen launch generated executables and set the game's screen size to second resolution (1024x768) in game options.
GOTO finish

:error0
ECHO %ERROR0%
GOTO finish
:error1
ECHO %ERROR1%
GOTO finish
:error2
ECHO %ERROR2%
GOTO finish
:error5
ECHO %ERROR5%
GOTO finish

:finish
::cleanup
IF EXIST jv.txt DEL jv.txt
IF EXIST %EMPIRES2_EXE% IF EXIST "%AOK_PATH%\%EMPIRES2_EXE%" DEL %EMPIRES2_EXE%
IF EXIST %INTERFAC_DRS% DEL %INTERFAC_DRS%
ECHO Press any key to quit...
PAUSE > nul
