@echo off
title IronHide — Test Suite
color 0E
echo.
echo  ================================================================
echo    IronHide Expert System — Test Suite
echo    7 Test Cases, 63+ Assertions
echo  ================================================================
echo.
where swipl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  [ERROR] swipl not found. See README.md for installation.
  pause
  exit /b 1
)
echo  [OK] SWI-Prolog found.
echo  [>>] Running tests...
echo.
swipl tests/test_cases.pl
pause
