@echo off
REM Double-click this file to start the app and open the browser.
cd /d "%~dp0"
title Dev News Aggregator
echo Starting Dev News Aggregator...
echo Close this window or press Ctrl+C to stop the app.
echo Do not click inside this window while it starts.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dev.ps1"
echo.
echo App stopped.
pause
