@echo off
title IronHide Expert System
color 0B
echo.
echo  ====================================================
echo    IronHide Expert System - Launcher
echo  ====================================================
echo.
echo  Checking for SWI-Prolog...
where swipl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  [ERROR] swipl not found in PATH.
  echo  Please install SWI-Prolog from: https://www.swi-prolog.org/download/stable
  echo  After installation, re-run this script.
  pause
  exit /b 1
)
echo  [OK] SWI-Prolog found.
echo.
echo  Starting IronHide server on http://localhost:8080
echo  Press Ctrl+C to stop.
echo.
start "" http://localhost:8080
swipl ironhide.pl
pause
