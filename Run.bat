@echo off
setlocal

set "DATA_DIR=%~dp0data"

:: Launch Control Console
start "Control Console" cmd /k "%DATA_DIR%\console_input.bat"