@echo off
rem ==========================================================================
rem  UT Millenium Launcher
rem  First run: finds Unreal Tournament, gets the free OldUnreal 469e patch,
rem  and builds a private game folder inside "UT Millenium Data".
rem  Your Unreal Tournament installation (Steam, GOG, CD) is only read, never changed.
rem  After that the game starts silently (no window), logging to
rem  "UT Millenium Data\launcher.log".
rem ==========================================================================
setlocal EnableExtensions DisableDelayedExpansion
title UT Millenium
cd /d "%~dp0"
set "BASE=%~dp0"
set "BASE=%BASE:~0,-1%"
set "DATA=%BASE%\UT Millenium Data"
set "MOD=%DATA%\Mod"
set "GAME=%DATA%\Game"
set "ADD=%DATA%\Add Maps"
set "LOG=%DATA%\launcher.log"
set "ERRFILE=%DATA%\last_problem.txt"
set "PATCH=OldUnreal-UTPatch469e-Windows-x86.zip"
set "PATCHURL=https://github.com/OldUnreal/UnrealTournamentPatches/releases/download/v469e/OldUnreal-UTPatch469e-Windows-x86.zip"
set "CORESHA=966a220dc3567495aea5b8a8baac9b3f2db547a75c5b8686a51ce2d6aa1d4740"
set "ENGINESHA=e3e93f5b9a251cb4759fbf542bc86192518775b5af91b767aef361f9118c686d"
set "PATCHSHA=8c94eb7e990f5480b1fb7bcb1bd15c2512da134dbf01bfa16e7f99f0a8a0ee86"
set "MENU=UT-Logo-Map.unr?Game=UTMillenium.UTMMenuGame"
set "PS=powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command"
set "UTM_SELF=%~f0"
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

if not exist "%DATA%" mkdir "%DATA%"
if /i "%~1"=="/hidden"  goto hidden
if /i "%~1"=="/addmaps" goto addmaps
if /i "%~1"=="/problem" goto problem

rem --------------------------------------------------------------------------
rem  Double-click: tidy up older versions, set up if needed, then start
rem  the game silently and close this window.
mode con: cols=80 lines=26 >nul 2>&1
call :migrate
echo [%date% %time%] start %*> "%LOG%"
if /i "%~1"=="/setup" goto setup
if not exist "%GAME%\setup.ok" goto setup
if not exist "%GAME%\System\UnrealTournament.exe" goto setup
call :banner
call :starthidden
call :loadingbar
exit /b 0

rem --------------------------------------------------------------------------
:setup
call :banner
echo(  %ESC%[93mFIRST TIME SETUP%ESC%[0m
echo(  Works with Unreal Tournament GOTY from Steam or GOG (or the CD).
echo(  It sets up the game in the "UT Millenium Data" folder and puts a
echo(  "UT Millenium" shortcut on your Desktop.
echo.
echo(  Looking for Unreal Tournament: Steam and GOG libraries, Program Files,
echo(  Games and other common folders on drives C, D, E, F, G and H...
echo.
call :findut
if defined UT goto foundut
echo(  %ESC%[91mCouldn't find it in any of the usual places.%ESC%[0m
goto askut

:foundut
echo(  %ESC%[93mFound Unreal Tournament here:%ESC%[0m
echo.
echo     %UT%
echo.
<nul set /p "=%ESC%[93m  Is this right? Press Y for yes or N to pick another folder: %ESC%[0m"
choice /c YN /n
if errorlevel 2 set "UT="
if defined UT goto haveut

:askut
echo.
echo   Please show UT Millenium where Unreal Tournament is installed:
echo   open that folder in File Explorer, drag it into this window,
echo   then press Enter.
echo   (It's the folder that has the System, Maps and Textures folders in it.)
echo.
set "UT="
set /p "UT=  > "
if not defined UT goto askut
set UT=%UT:"=%
if "%UT:~-1%"=="\" set "UT=%UT:~0,-1%"
if exist "%UT%\System\Botpack.u" if exist "%UT%\Maps\CTF-Face.unr" goto haveut
echo.
echo(  %ESC%[91mThat folder doesn't look like Unreal Tournament.%ESC%[0m Please try again.
goto askut

:haveut
echo UT=%UT%>> "%LOG%"
echo.

rem ---- UT already has the OldUnreal 469e update? Then use it as it is.
call :hashof "%UT%\System\Engine.dll"
if /i not "%H%"=="%ENGINESHA%" goto needpatch
call :hashof "%UT%\System\Core.dll"
if /i not "%H%"=="%CORESHA%" goto needpatch
echo(  %ESC%[93m[1/4]%ESC%[0m Your Unreal Tournament already has the OldUnreal 469e update.
echo(        No download needed.
if exist "%GAME%" rmdir /s /q "%GAME%"
robocopy "%UT%\System" "%GAME%\System" /E /XF *.ini *.log /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
echo(  %ESC%[93m[2/4]%ESC%[0m Game files copied.
goto commonfiles

:needpatch
rem ---- the free OldUnreal patch: already here, in Downloads, or download it
set "ZIP=%DATA%\%PATCH%"
call :checkzip "%ZIP%"
if not errorlevel 1 goto zipok
call :checkzip "%BASE%\%PATCH%"
if not errorlevel 1 move /y "%BASE%\%PATCH%" "%ZIP%" >nul & goto zipok
call :checkzip "%USERPROFILE%\Downloads\%PATCH%"
if not errorlevel 1 copy /y "%USERPROFILE%\Downloads\%PATCH%" "%ZIP%" >nul & goto zipok
echo(  UT Millenium needs the free %ESC%[93mOldUnreal 469e update%ESC%[0m for Unreal Tournament:
echo(  the popular community patch that keeps UT99 running on modern Windows,
echo(  made by the OldUnreal team (AnthraX, Higor, Buggie, Dots, Smirftsch and
echo(  contributors). Downloading it once from github.com/OldUnreal (101 MB)...
echo.
curl.exe -L --fail --progress-bar -o "%ZIP%" "%PATCHURL%"
call :checkzip "%ZIP%"
if not errorlevel 1 goto zipok
del /q "%ZIP%" >nul 2>&1
call :fail "UT Millenium couldn't download the free OldUnreal 469e update (101 MB)." "It's the popular community patch for Unreal Tournament that keeps it running" "on modern Windows, made by the OldUnreal team (AnthraX, Higor, Buggie, Dots," "Smirftsch and contributors). UT Millenium needs it only once." " " "Please connect to the internet and start UT Millenium again." " " "Or download it yourself from github.com/OldUnreal/UnrealTournamentPatches" "(release v469e, file OldUnreal-UTPatch469e-Windows-x86.zip)," "put it into your Downloads folder and start UT Millenium again."
goto problem

:zipok
echo(  %ESC%[93m[1/4]%ESC%[0m Free OldUnreal update ready.

rem ---- fresh game folder
if exist "%GAME%" rmdir /s /q "%GAME%"
mkdir "%GAME%\_patch"
tar.exe -xf "%ZIP%" -C "%GAME%\_patch" >> "%LOG%" 2>&1
if exist "%GAME%\_patch\System\UnrealTournament.exe" goto unpacked
call :fail "Something went wrong while unpacking the game files." "Please start UT Millenium again. If it happens again, your disk may be full."
goto problem
:unpacked
echo(  %ESC%[93m[2/4]%ESC%[0m Update unpacked.

rem ---- System = your UT System files (no programs) + the update on top
robocopy "%UT%\System" "%GAME%\System" /E /XF *.dll *.exe *.ini *.log /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\System" "%GAME%\System" /E /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\SystemLocalized\int" "%GAME%\System" *.int /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\Textures" "%GAME%\Textures" /E /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
rmdir /s /q "%GAME%\_patch"

:commonfiles
mkdir "%GAME%\Maps" "%GAME%\Sounds" "%GAME%\Music" "%GAME%\Textures" 2>nul
copy /y "%GAME%\System\Default.ini" "%GAME%\System\UnrealTournament.ini" >nul
copy /y "%GAME%\System\DefUser.ini" "%GAME%\System\User.ini" >nul
if exist "%GAME%\System\UnrealTournament.ini" goto built
call :fail "Something went wrong while copying the game files." "Please start UT Millenium again. If it happens again, your disk may be full."
goto problem
:built
echo(  %ESC%[93m[3/4]%ESC%[0m Game folder ready (your Unreal Tournament files were only read, not changed).

set "UTM_GAME=%GAME%"
%PS% "iex (Get-Content -Raw -LiteralPath '%MOD%\autotaunt.txt')" >> "%LOG%" 2>&1
call :shortcut
> "%GAME%\utpath.txt" echo %UT%
> "%GAME%\setup.ok" echo 1
if exist "%GAME%\shortcut.done" echo(  %ESC%[93m[4/4]%ESC%[0m Desktop shortcut "UT Millenium" (with the UT icon) created.
if not exist "%GAME%\shortcut.done" echo(  %ESC%[93m[4/4]%ESC%[0m Windows didn't allow a Desktop shortcut - use "UT Millenium Launcher".
echo.
echo(  %ESC%[92mAll done!%ESC%[0m
echo.
echo(  %ESC%[92mStarting UT Millenium... enjoy!%ESC%[0m
echo setup ok>> "%LOG%"
timeout /t 2 /nobreak >nul
call :starthidden
call :loadingbar
exit /b 0

rem --------------------------------------------------------------------------
rem  Silent part: runs without a window while you play.
:hidden
echo [%date% %time%] hidden start>> "%LOG%"
set "UT="
set /p UT=<"%GAME%\utpath.txt"
if exist "%UT%\System\Botpack.u" goto hiddenok
call :fail "UT Millenium can't find your Unreal Tournament folder any more." "Did it move? Start UT Millenium again and it will ask you where it is now."
del /q "%GAME%\setup.ok" >nul 2>&1
call :showproblem
exit /b 1
:hiddenok
call :update
if not errorlevel 1 goto launch
call :fail "UT Millenium couldn't get its settings ready." "Please start it again. If this keeps happening, delete the folder 'UT Millenium Data\Game' and start again (it will set itself up anew)."
call :showproblem
exit /b 1
:launch
echo launching>> "%LOG%"
start "" /wait /d "%GAME%\System" "%GAME%\System\UnrealTournament.exe" %MENU% -forcelogflush
echo game closed>> "%LOG%"
findstr /i /c:"bAddMapsRequest=True" "%GAME%\System\UTMillenium.ini" >nul 2>&1
if errorlevel 1 exit /b 0
start "UT Millenium - Add Maps" "%ComSpec%" /c ""%~f0" /addmaps"
exit /b 0

rem --------------------------------------------------------------------------
rem  Every start: copy the mod files, set window sizes and search paths.
:update
copy /y "%MOD%\UTMillenium.u" "%GAME%\System\" >nul || exit /b 1
copy /y "%MOD%\UTMillenium.int" "%GAME%\System\" >nul
mkdir "%GAME%\Maps" "%GAME%\Sounds" "%GAME%\Music" 2>nul
set "UTM_UT=%UT%"
set "UTM_GAME=%GAME%"
%PS% "iex (Get-Content -Raw -LiteralPath '%MOD%\update.txt')" >> "%LOG%" 2>&1
if errorlevel 1 exit /b 1
exit /b 0

rem --------------------------------------------------------------------------
:addmaps
mode con: cols=80 lines=26 >nul 2>&1
call :banner
echo(  %ESC%[93mADD MAPS%ESC%[0m
echo.
echo   A folder called "Add Maps" is opening now.
echo   Put your downloaded maps in there: .unr files, .zip downloads
echo   or whole folders - anything is fine.
echo.
if not exist "%ADD%" mkdir "%ADD%"
start "" explorer "%ADD%"
echo   When you're done, come back to this window and
pause
echo.
echo   Adding maps...
set "UT="
set /p UT=<"%GAME%\utpath.txt"
set /a NMAPS=0
if exist "%GAME%\_import" rmdir /s /q "%GAME%\_import"
mkdir "%GAME%\_import"
robocopy "%ADD%" "%GAME%\_import\files" /E /XD Imported /NFL /NDL /NJH /NJS /NP >nul 2>&1
for /r "%GAME%\_import\files" %%Z in (*.zip) do (
  mkdir "%GAME%\_import\z\%%~nZ" 2>nul
  tar.exe -xf "%%Z" -C "%GAME%\_import\z\%%~nZ" >nul 2>&1
)
for /r "%GAME%\_import" %%F in (*.unr) do if not exist "%UT%\Maps\%%~nxF" if not exist "%GAME%\Maps\%%~nxF" (copy /y "%%F" "%GAME%\Maps\" >nul & set /a NMAPS+=1 & echo     + %%~nF)
for /r "%GAME%\_import" %%F in (*.utx) do if not exist "%UT%\Textures\%%~nxF" copy /y "%%F" "%GAME%\Textures\" >nul
for /r "%GAME%\_import" %%F in (*.uax) do if not exist "%UT%\Sounds\%%~nxF" copy /y "%%F" "%GAME%\Sounds\" >nul
for /r "%GAME%\_import" %%F in (*.umx) do if not exist "%UT%\Music\%%~nxF" copy /y "%%F" "%GAME%\Music\" >nul
for /r "%GAME%\_import" %%F in (*.u *.int) do if not exist "%GAME%\System\%%~nxF" copy /y "%%F" "%GAME%\System\" >nul
rmdir /s /q "%GAME%\_import"
if not exist "%ADD%\Imported" mkdir "%ADD%\Imported"
for /f "delims=" %%I in ('dir /b "%ADD%" ^| findstr /v /x /c:"Imported"') do move /y "%ADD%\%%I" "%ADD%\Imported\" >nul 2>&1
echo.
if %NMAPS%==0 (echo   No new maps found in the "Add Maps" folder.) else (echo(  %ESC%[92mAdded %NMAPS% new map^(s^).%ESC%[0m They are in the random pick now.)
echo addmaps %NMAPS%>> "%LOG%"
echo.
echo   Starting UT Millenium again...
timeout /t 2 /nobreak >nul
call :banner
call :starthidden
call :loadingbar
exit /b 0

rem --------------------------------------------------------------------------
rem  Start the silent part without any window.
:starthidden
del /q "%GAME%\System\UnrealTournament.log" >nul 2>&1
del /q "%ERRFILE%" >nul 2>&1
if not exist "%GAME%\shortcut.ok" call :shortcut
%PS% "Start-Process -FilePath $env:ComSpec -ArgumentList ('/c ' + [char]34 + [char]34 + $env:UTM_SELF + [char]34 + ' /hidden' + [char]34) -WindowStyle Hidden" >> "%LOG%" 2>&1
exit /b 0

rem --------------------------------------------------------------------------
rem  Old school loading indicator while the game starts. The window closes
rem  the moment the main menu is up (the game writes that into its log).
:loadingbar
set "LF=%GAME%\System\UnrealTournament.log"
set /a F=0
call :now
set /a T0=NOW
:lbloop
findstr /c:"UTM EnterLevel mode=0" "%LF%" >nul 2>&1 && goto lbend
if exist "%ERRFILE%" goto lbend
set /a S=F %% 4, DT=(F / 3) %% 4
if %S%==0 set "SP=|"
if %S%==1 set "SP=/"
if %S%==2 set "SP=-"
if %S%==3 set "SP=\"
if %DT%==0 set "DOTS=   "
if %DT%==1 set "DOTS=.  "
if %DT%==2 set "DOTS=.. "
if %DT%==3 set "DOTS=..."
<nul set /p "=%ESC%[1G%ESC%[2K  %ESC%[93m[%SP%]  LOADING%DOTS%%ESC%[0m"
set /a F+=1
call :now
set /a W=NOW-T0
if %W% LSS 0 set /a W+=8640000
rem  stop after 2 minutes (the game keeps loading anyway)
if %W% GTR 12000 goto lbend
call :nap
goto lbloop
:lbend
exit /b 0

rem  a short pause (ping to an address that never answers;
rem  if there's no network at all it fails at once, then wait 1 second)
:nap
call :now
set /a N0=NOW
ping -n 1 -w 150 192.0.2.1 >nul 2>&1
call :now
set /a N1=NOW-N0
if %N1% LSS 0 set /a N1+=8640000
if %N1% LSS 10 timeout /t 1 /nobreak >nul
exit /b 0

rem  NOW = time of day in 1/100 s
:now
set "TM=%time: =0%"
set /a NOW=((1%TM:~0,2%-100)*3600+(1%TM:~3,2%-100)*60+(1%TM:~6,2%-100))*100+(1%TM:~9,2%-100)
exit /b 0

rem  One time: Desktop shortcut with the Unreal Tournament icon.
:shortcut
set "UTM_GAME=%GAME%"
%PS% "iex (Get-Content -Raw -LiteralPath '%MOD%\shortcut.txt')" >> "%LOG%" 2>&1
> "%GAME%\shortcut.ok" echo 1
exit /b 0

rem  Remember a problem in plain words (shown by :problem).
:fail
> "%ERRFILE%" type nul
:failline
if "%~1"=="" exit /b 0
>> "%ERRFILE%" echo(%~1
>> "%LOG%" echo PROBLEM: %~1
shift
goto failline

rem  From the silent part: open a window that explains the problem.
:showproblem
start "UT Millenium" "%ComSpec%" /c ""%~f0" /problem"
exit /b 0

:problem
mode con: cols=80 lines=36 >nul 2>&1
call :banner
echo(  %ESC%[91mSorry, something went wrong.%ESC%[0m
echo.
if exist "%ERRFILE%" (for /f "usebackq delims=" %%L in ("%ERRFILE%") do echo   %%L)
echo.
echo   (Details for the curious: UT Millenium Data\launcher.log)
echo.
pause
exit /b 1

rem --------------------------------------------------------------------------
rem  Tidy up files from older UT Millenium versions.
:migrate
if exist "%BASE%\Game\setup.ok" if not exist "%GAME%" move "%BASE%\Game" "%GAME%" >nul 2>&1
if exist "%BASE%\Data\%PATCH%" if not exist "%DATA%\%PATCH%" move "%BASE%\Data\%PATCH%" "%DATA%\" >nul 2>&1
if exist "%BASE%\Add Maps" if not exist "%ADD%" move "%BASE%\Add Maps" "%ADD%" >nul 2>&1
for %%F in ("UT Millenium.cmd" "UT Millenium.exe" "README.txt" "launcher.log") do if exist "%BASE%\%%~F" del /q "%BASE%\%%~F" >nul 2>&1
if exist "%BASE%\Data" rmdir /s /q "%BASE%\Data" >nul 2>&1
if exist "%BASE%\Game" if exist "%GAME%\setup.ok" rmdir /s /q "%BASE%\Game" >nul 2>&1
exit /b 0

rem --------------------------------------------------------------------------
:findut
set "UT="
for /f "usebackq delims=" %%P in (`%PS% "iex (Get-Content -Raw -LiteralPath '%MOD%\findut.txt')" 2^>nul`) do if not defined UT set "UT=%%P"
exit /b 0

rem  errorlevel 0 = the zip exists and its SHA-256 matches the official file
rem  H = SHA256 of a file (empty if it's missing)
:hashof
set "H="
if not exist "%~1" exit /b 1
for /f "delims=" %%H in ('certutil -hashfile "%~1" SHA256 ^| findstr /v ":"') do (
  set "H=%%H"
  goto hashdone
)
exit /b 1
:hashdone
set "H=%H: =%"
exit /b 0

:checkzip
if not exist "%~1" exit /b 1
for /f "delims=" %%H in ('certutil -hashfile "%~1" SHA256 ^| findstr /v ":"') do (
  set "H=%%H"
  goto gothash
)
exit /b 1
:gothash
set "H=%H: =%"
if /i "%H%"=="%PATCHSHA%" exit /b 0
exit /b 1

rem --------------------------------------------------------------------------
:banner
cls
echo(
echo(%ESC%[93m   _   _ _____  ___  ________ _      _      _____ _   _ _____ _   ____  ___%ESC%[0m
echo(%ESC%[93m  ^| ^| ^| ^|_   _^| ^|  \/  ^|_   _^| ^|    ^| ^|    ^|  ___^| \ ^| ^|_   _^| ^| ^| ^|  \/  ^|%ESC%[0m
echo(%ESC%[93m  ^| ^| ^| ^| ^| ^|   ^| .  . ^| ^| ^| ^| ^|    ^| ^|    ^| ^|__ ^|  \^| ^| ^| ^| ^| ^| ^| ^| .  . ^|%ESC%[0m
echo(%ESC%[93m  ^| ^| ^| ^| ^| ^|   ^| ^|\/^| ^| ^| ^| ^| ^|    ^| ^|    ^|  __^|^| . ` ^| ^| ^| ^| ^| ^| ^| ^|\/^| ^|%ESC%[0m
echo(%ESC%[93m  ^| ^|_^| ^| ^| ^|   ^| ^|  ^| ^|_^| ^|_^| ^|____^| ^|____^| ^|___^| ^|\  ^|_^| ^|_^| ^|_^| ^| ^|  ^| ^|%ESC%[0m
echo(%ESC%[93m   \___/  \_/   \_^|  ^|_/\___/\_____/\_____/\____/\_^| \_/\___/ \___/\_^|  ^|_/%ESC%[0m
echo(%ESC%[91m  ---------------------------------------------------------------------------%ESC%[0m
echo(%ESC%[37m                  Quick Play for Unreal Tournament (1999).%ESC%[0m
echo(%ESC%[93m           INSTA-PLAY  ^|^|^|  INSTA-FRAG  ^|^|^|  INSTA-DOPAMINE%ESC%[0m
echo(%ESC%[91m  ---------------------------------------------------------------------------%ESC%[0m
echo(
exit /b 0
