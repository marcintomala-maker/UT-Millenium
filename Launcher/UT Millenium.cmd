@echo off
rem ==========================================================================
rem  UT Millenium launcher
rem  First run: finds Unreal Tournament, gets the official OldUnreal 469e
rem  patch, and builds a private "Game" folder next to this file.
rem  Your Steam installation is only read, never changed.
rem  Uses only tools that come with Windows 10/11 (curl, tar, robocopy,
rem  certutil, PowerShell).
rem ==========================================================================
setlocal EnableExtensions DisableDelayedExpansion
title UT Millenium
cd /d "%~dp0"
set "BASE=%~dp0"
set "BASE=%BASE:~0,-1%"
set "GAME=%BASE%\Game"
set "LOG=%BASE%\launcher.log"
set "PATCH=OldUnreal-UTPatch469e-Windows-x86.zip"
set "PATCHURL=https://github.com/OldUnreal/UnrealTournamentPatches/releases/download/v469e/OldUnreal-UTPatch469e-Windows-x86.zip"
set "PATCHSHA=8c94eb7e990f5480b1fb7bcb1bd15c2512da134dbf01bfa16e7f99f0a8a0ee86"
set "MENU=UT-Logo-Map.unr?Game=UTMillenium.UTMMenuGame"
set "PS=powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command"

mode con: cols=80 lines=26 >nul 2>&1
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
echo [%date% %time%] start %* > "%LOG%"

if /i "%~1"=="/setup" goto setup
if not exist "%GAME%\setup.ok" goto setup
if not exist "%GAME%\System\UnrealTournament.exe" goto setup
set "UT="
set /p UT=<"%GAME%\utpath.txt"
if not exist "%UT%\System\Botpack.u" goto setup
goto play

rem --------------------------------------------------------------------------
:setup
call :banner
echo(%ESC%[93m  FIRST TIME SETUP%ESC%[0m
echo.
call :findut
if not defined UT goto askut
echo(  %ESC%[93mFound Unreal Tournament here:%ESC%[0m
echo.
echo     %UT%
echo.
choice /c YN /n /m "  Use this folder? [Y/N] "
if errorlevel 2 set "UT="
if defined UT goto haveut

:askut
echo.
echo   Drag your Unreal Tournament folder into this window
echo   (the folder that contains System, Maps and Textures)
echo   and press Enter:
echo.
set "UT="
set /p "UT=  > "
if not defined UT goto askut
set UT=%UT:"=%
if "%UT:~-1%"=="\" set "UT=%UT:~0,-1%"
if exist "%UT%\System\Botpack.u" if exist "%UT%\Maps\CTF-Face.unr" goto haveut
echo.
echo   That doesn't look like Unreal Tournament. Try again.
goto askut

:haveut
echo UT=%UT%>> "%LOG%"
echo.

rem ---- the patch: Data\, next to this file, Downloads, or download it
if not exist "%BASE%\Data" mkdir "%BASE%\Data"
set "ZIP=%BASE%\Data\%PATCH%"
call :checkzip "%ZIP%"
if not errorlevel 1 goto zipok
call :checkzip "%BASE%\%PATCH%"
if not errorlevel 1 copy /y "%BASE%\%PATCH%" "%ZIP%" >nul & goto zipok
call :checkzip "%USERPROFILE%\Downloads\%PATCH%"
if not errorlevel 1 copy /y "%USERPROFILE%\Downloads\%PATCH%" "%ZIP%" >nul & goto zipok
echo   Downloading the free OldUnreal 469e patch (101 MB) from GitHub...
echo.
curl.exe -L --fail --progress-bar -o "%ZIP%" "%PATCHURL%"
call :checkzip "%ZIP%"
if not errorlevel 1 goto zipok
echo.
echo   Couldn't download the patch. Check your internet connection, or
echo   download %PATCH%
echo   from github.com/OldUnreal/UnrealTournamentPatches (release v469e)
echo   and put it next to this file. Then start again.
goto failed

:zipok
echo(  %ESC%[93m[1/4]%ESC%[0m OldUnreal 469e patch ready.

rem ---- fresh game folder
if exist "%GAME%" rmdir /s /q "%GAME%"
mkdir "%GAME%\_patch"
tar.exe -xf "%ZIP%" -C "%GAME%\_patch" >> "%LOG%" 2>&1
if not exist "%GAME%\_patch\System\UnrealTournament.exe" (
  echo   Couldn't unpack the patch.
  goto failed
)
echo(  %ESC%[93m[2/4]%ESC%[0m Patch unpacked.

rem ---- System = your UT System files (no programs) + the patch on top
robocopy "%UT%\System" "%GAME%\System" /E /XF *.dll *.exe *.ini /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\System" "%GAME%\System" /E /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\SystemLocalized\int" "%GAME%\System" *.int /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
robocopy "%GAME%\_patch\Textures" "%GAME%\Textures" /E /NFL /NDL /NJH /NJS /NP >> "%LOG%" 2>&1
mkdir "%GAME%\Maps" "%GAME%\Sounds" "%GAME%\Music" 2>nul
copy /y "%GAME%\System\Default.ini" "%GAME%\System\UnrealTournament.ini" >nul
copy /y "%GAME%\System\DefUser.ini" "%GAME%\System\User.ini" >nul
rmdir /s /q "%GAME%\_patch"
if not exist "%GAME%\System\UnrealTournament.ini" (
  echo   Couldn't build the game folder.
  goto failed
)
echo(  %ESC%[93m[3/4]%ESC%[0m Game folder built (your Steam files were only read).

rem ---- one-time settings: auto taunt on
set "UTM_GAME=%GAME%"
%PS% "iex (Get-Content -Raw -LiteralPath '%BASE%\Data\autotaunt.txt')" >> "%LOG%" 2>&1

> "%GAME%\utpath.txt" echo %UT%
> "%GAME%\setup.ok" echo 1
echo(  %ESC%[93m[4/4]%ESC%[0m Done! Starting UT Millenium...
echo setup ok>> "%LOG%"
timeout /t 2 /nobreak >nul
goto play

rem --------------------------------------------------------------------------
:play
call :banner
echo(%ESC%[93m  Loading...%ESC%[0m the menu opens in a few seconds.
echo.
call :update
if errorlevel 1 goto failed
echo launching>> "%LOG%"
echo(%ESC%[92m  UT Millenium is running. Have fun!%ESC%[0m
echo.
echo   Keep this window open while you play (you can minimize it).
echo   It closes by itself when you EXIT the game.
rem this window waits while you play; it's needed for ADD MAPS
start "" /wait /d "%GAME%\System" "%GAME%\System\UnrealTournament.exe" %MENU%
echo game closed>> "%LOG%"
findstr /i /c:"bAddMapsRequest=True" "%GAME%\System\UTMillenium.ini" >nul 2>&1
if errorlevel 1 goto end
call :addmaps
goto play

rem --------------------------------------------------------------------------
rem  Every start: copy the mod files, set window sizes and search paths.
:update
copy /y "%BASE%\Data\UTMillenium.u" "%GAME%\System\" >nul || (echo   Data\UTMillenium.u is missing. & exit /b 1)
copy /y "%BASE%\Data\UTMillenium.int" "%GAME%\System\" >nul
mkdir "%GAME%\Maps" "%GAME%\Sounds" "%GAME%\Music" 2>nul
set "UTM_UT=%UT%"
set "UTM_GAME=%GAME%"
%PS% "iex (Get-Content -Raw -LiteralPath '%BASE%\Data\update.txt')" >> "%LOG%" 2>&1
if errorlevel 1 (echo   Couldn't update the game settings, see launcher.log & exit /b 1)
exit /b 0

rem --------------------------------------------------------------------------
:addmaps
set "ADD=%BASE%\Add Maps"
if not exist "%ADD%" mkdir "%ADD%"
cls
echo.
echo   ADD MAPS
echo   --------
echo   A folder called "Add Maps" is opening now.
echo   Put your downloaded maps there: .unr files, .zip downloads, or whole folders.
echo.
start "" explorer "%ADD%"
echo   When you're done, come back to this window and
pause
echo.
echo   Importing...
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
rem move the imported things out of the way so they aren't imported twice
if not exist "%ADD%\Imported" mkdir "%ADD%\Imported"
for /f "delims=" %%I in ('dir /b "%ADD%" ^| findstr /v /x /c:"Imported"') do move /y "%ADD%\%%I" "%ADD%\Imported\" >nul 2>&1
echo.
echo   Added %NMAPS% new map(s). Starting UT Millenium again...
echo addmaps %NMAPS%>> "%LOG%"
timeout /t 3 /nobreak >nul
exit /b 0

rem --------------------------------------------------------------------------
:findut
set "UT="
for /f "usebackq delims=" %%P in (`%PS% "iex (Get-Content -Raw -LiteralPath '%BASE%\Data\findut.txt')" 2^>nul`) do if not defined UT set "UT=%%P"
exit /b 0

rem --------------------------------------------------------------------------
rem  errorlevel 0 = the zip exists and its SHA-256 matches the official file
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
:failed
echo.
echo(  %ESC%[91mSetup didn't finish.%ESC%[0m Details are in launcher.log next to this file.
echo failed>> "%LOG%"
pause
exit /b 1

:end
exit /b 0

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
echo(%ESC%[37m          a quick-play front end for Unreal Tournament (1999)%ESC%[0m
echo(%ESC%[91m  ---------------------------------------------------------------------------%ESC%[0m
echo(
exit /b 0
