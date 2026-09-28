@echo off
title IronHide Expert System — CLI
color 0A
echo.
echo  ================================================================
echo    IronHide Expert System — CLI Mode
echo    Fitness ^& Diet Recommendation Expert System (SWI-Prolog)
echo  ================================================================
echo.
where swipl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  [ERROR] SWI-Prolog ^(swipl^) not found in your PATH.
  echo.
  echo  Please install SWI-Prolog from:
  echo    https://www.swi-prolog.org/download/stable
  echo.
  echo  During installation, ensure "Add swipl to PATH" is checked.
  echo  Then restart this terminal and run this script again.
  echo.
  pause
  exit /b 1
)
echo  [OK] SWI-Prolog found.
echo  [>>] Starting IronHide...
echo.
swipl ironhide_standalone.pl
pause
