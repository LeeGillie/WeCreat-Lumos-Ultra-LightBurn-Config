@echo off
REM ---------------------------------------------------------------------------
REM  WeCreat Lumos Ultra - LightBurn configuration project
REM  Launcher for the test machine (the PC with the laser attached).
REM
REM  This is the CANONICAL, version-controlled copy. Deploy it to the root of a
REM  share the test machine can read, so the operator types one short path:
REM
REM      copy "tools\lumos-launcher.cmd"  D:\lumos.cmd        (on the share host)
REM      then on the test machine, Win+R:   \\<host>\D\lumos.cmd
REM
REM  Opens a menu: Stage 0 (USB), Stage 1 (serial), Stage 2 (HTTP API).
REM  All read-only. Nothing fires. One opt-in probe moves the head and says so.
REM ---------------------------------------------------------------------------
setlocal
title WeCreat Lumos Ultra - test machine console

REM %~dp0 is wherever this file was launched from, so this works over any share
REM name, drive letter or IP address without editing. When deployed to a drive
REM root the repo sits under DevHome\; when run from tools\ it is two levels up.
set "PS=%~dp0DevHome\WeCreat Lumos Ultra Lightburn Config\tools\test-machine.ps1"
if not exist "%PS%" set "PS=%~dp0test-machine.ps1"
if not exist "%PS%" set "PS=%~dp0..\tools\test-machine.ps1"

if not exist "%PS%" (
  echo.
  echo   Could not find test-machine.ps1 near this launcher.
  echo   Looked under: %~dp0
  echo.
  echo   Launch this file from the share, e.g. \\cortex\D\lumos.cmd
  echo.
  pause
  exit /b 1
)

echo.
echo   Launching: %PS%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo   PowerShell exited with code %RC%.
  echo.
  pause
)
endlocal
