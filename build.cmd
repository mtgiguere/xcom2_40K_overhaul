@echo off
REM Build the Astartes mod from the command line (no ModBuddy needed).
REM Usage: build.cmd [default|debug]
set CFG=%1
if "%CFG%"=="" set CFG=default
powershell.exe -NonInteractive -ExecutionPolicy Bypass -File "%~dp0.scripts\build.ps1" -srcDirectory "%~dp0." -sdkPath "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2 War of the Chosen SDK" -gamePath "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen" -config %CFG%
