@ECHO OFF

SET REG_AOC_KEY="HKLM\SOFTWARE\Microsoft\DirectPlay\Applications\Age of Empires II - The Conquerors Expansion"
SET REG_PATH_VALUE=Path

SET INTERFAC_DRS=interfac.drs
SET AGE2X1_EXE=age2_x1.exe
SET SLPLIST_FILE=slplist.txt

SET AGE2X1_EXE_SIZE=2699309

SET ERROR0=ERROR: Java seems to be not installed on your computer. Download and install JRE from http://www.oracle.com/technetwork/java/javase/downloads/index.html. If you have JRE installed and you still see this message, add java to your PATH variable. See http://docs.oracle.com/javase/tutorial/essential/environment/paths.html
SET ERROR1=ERROR: Game installation nor %INTERFAC_DRS% found, copy %INTERFAC_DRS% to this directory and launch script again.
SET ERROR3=ERROR: Game installation nor %AGE2X1_EXE% found, copy %AGE2X1_EXE% to this directory and launch script again.
SET ERROR4=ERROR: %AGE2X1_EXE% not found, copy %AGE2X1_EXE% to this directory and launch script again.
SET ERROR6=ERROR: Widescreen patch is not supported for your version of AOC executable %AGE2X1_EXE% file. Download supported executable from http://code.google.com/p/aoe2wspatch/downloads/list and copy it to this directory.

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
:aoccheck
IF NOT EXIST %AGE2X1_EXE% GOTO getaoc
ECHO %AGE2X1_EXE% found in current directory. Using it...
GOTO process

:getdrs
IF NOT DEFINED AOK_PATH GOTO error1
IF NOT EXIST "%AOK_PATH%\Data\%INTERFAC_DRS%" GOTO error1
ECHO %INTERFAC_DRS% found in %AOK_PATH%\Data\ directory. Copying...
COPY "%AOK_PATH%\Data\%INTERFAC_DRS%" %INTERFAC_DRS%
GOTO aoccheck

:getaoc
IF NOT DEFINED AOC_PATH GOTO :ingetaoc
IF NOT EXIST "%AOC_PATH%\%AGE2X1_EXE%" GOTO error3
ECHO %AGE2X1_EXE% found in %AOC_PATH%\ directory. Copying...
COPY "%AOC_PATH%\%AGE2X1_EXE%" %AGE2X1_EXE%
GOTO process

:ingetaoc
SET /P INPUT="AOC game installation not found. Do you have The Conquerors Expansion installed (Y/N)?"
IF /I "%INPUT:~,1%"=="y" GOTO error4
IF /I "%INPUT:~,1%"=="n" GOTO process

:process
:: check if we have supported executables
SET AOC_SIZE=0
IF EXIST %AGE2X1_EXE% FOR /F "usebackq" %%A IN ('%AGE2X1_EXE%') DO SET AOC_SIZE=%%~zA

IF EXIST %AGE2X1_EXE% IF NOT %AOC_SIZE% == %AGE2X1_EXE_SIZE% GOTO error6

::patch executables
IF EXIST %AGE2X1_EXE% patcher %AGE2X1_EXE% aoc10c_offsets

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
REM MOVE Empires2_*.exe "%AOK_PATH%"
MOVE %INTERFAC_WS% "%AOK_PATH%\Data\"
IF EXIST age2_x1_*.exe MOVE age2_x1_*.exe "%AOC_PATH%"

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
:error3
ECHO %ERROR3%
GOTO finish
:error4
ECHO %ERROR4%
GOTO finish
:error6
ECHO %ERROR6%
GOTO finish

:finish
::cleanup
IF EXIST jv.txt DEL jv.txt
IF EXIST %AGE2X1_EXE% IF EXIST "%AOC_PATH%\%AGE2X1_EXE%" DEL %AGE2X1_EXE%
IF EXIST %INTERFAC_DRS% DEL %INTERFAC_DRS%
ECHO Press any key to quit...
PAUSE > nul
