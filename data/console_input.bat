@echo off
setlocal enabledelayedexpansion

:: Enable ANSI colors
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "C_RESET=%ESC%[0m"
set "C_SYS=%ESC%[36m"
set "C_DEV=%ESC%[33m"
set "C_ERR=%ESC%[31m"
set "C_GREEN=%ESC%[32m"

::resolve root dir
for %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI"

:: Set local ADB path inside data directory
set "DATA_DIR=%~dp0"
set "ADB_CMD=%DATA_DIR%adb.exe"

if not exist "%ADB_CMD%" set "ADB_CMD=adb"

title Control Console

cls
:SHOW_MENU
echo %C_SYS%==================================================%C_RESET%
echo %C_SYS%[CONTROL CONSOLE]  ADB Functions%C_RESET%
echo %C_SYS%==================================================%C_RESET%
echo   %C_DEV%Custom Tools:
echo   %C_DEV%   1%C_RESET% : Drag 'N Drop APK installer and file copier
echo.
echo   %C_DEV%Common Functions:
echo   %C_DEV%   A%C_RESET% : List Installed 3rd-Party Apps
echo   %C_DEV%   S%C_RESET% : Take Screenshot (Save to PC)
echo   %C_DEV%   I%C_RESET% : Show Device Info (Battery, IP, Storage)
echo   %C_DEV%   U%C_RESET% : Uninstall an App
echo   %C_DEV%   C%C_RESET% : Clear App Data / Cache
echo   %C_DEV%   W%C_RESET% : Enable Wireless ADB (Port 5555)
echo   %C_DEV%   R%C_RESET% : Reboot Device
echo.
echo   %C_DEV%Console commands:
echo   %C_DEV%   HELP%C_RESET% : Show available functions
echo   %C_DEV%   CLEAR%C_RESET% : Clear terminal
echo.
echo   %C_DEV%Advanced Functions:
echo   %C_DEV%   Oa%C_RESET% : Optimize (TRIM + Clear app storage/cache)
echo   %C_DEV%   Ob%C_RESET% : Optimize (TRIM + Clear ONLY app cache)
echo %C_SYS%==================================================%C_RESET%
echo.

:INPUT_LOOP
set "CMD="
set /p "CMD=> "

if /i "!CMD!"=="1" goto DRAG_N_DROP_TOOL
::
if /i "!CMD!"=="A" goto SHOW_APPS
if /i "!CMD!"=="S" goto TAKE_SCREENSHOT
if /i "!CMD!"=="I" goto SHOW_INFO
if /i "!CMD!"=="U" goto UNINSTALL_APP
if /i "!CMD!"=="C" goto CLEAR_DATA
if /i "!CMD!"=="W" goto WIRELESS_ADB
if /i "!CMD!"=="R" goto REBOOT_DEVICE
::
if /i "!CMD!"=="HELP" goto HELP
if /i "!CMD!"=="CLEAR" goto CLEAR
::
if /i "!CMD!"=="Oa" goto OPTIMIZE_DEVICE
if /i "!CMD!"=="Ob" goto OPTIMIZE2_DEVICE

if not "!CMD!"=="" echo %C_ERR%Unknown command.%C_RESET%
echo.
goto INPUT_LOOP


:: Functions
:CHECK_DEVICE
"%ADB_CMD%" devices | findstr /R /C:"device$" >nul
if !errorlevel! neq 0 (
    echo %C_ERR%[ERROR] No ADB device connected.%C_RESET%
    echo.
    exit /b 1
)
exit /b 0

:SHOW_APPS
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
echo %C_SYS%================ Installed Packages (-3) ================%C_RESET%
"%ADB_CMD%" shell pm list packages -3
echo %C_SYS%========================================================%C_RESET%
echo.
goto INPUT_LOOP

:TAKE_SCREENSHOT
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
set "TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
set "OUT_FILE=%ROOT_DIR%\screenshot_!TIMESTAMP!.png"

echo %C_SYS%[INFO] Capturing screenshot...%C_RESET%
"%ADB_CMD%" shell screencap -p /sdcard/screencap.png
"%ADB_CMD%" pull /sdcard/screencap.png "!OUT_FILE!" >nul 2>&1
"%ADB_CMD%" shell rm /sdcard/screencap.png
echo %C_GREEN%[SUCCESS] Saved to: !OUT_FILE!%C_RESET%
echo.
goto INPUT_LOOP

:SHOW_INFO
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
echo %C_SYS%================ Device Details ================%C_RESET%
for /f "tokens=*" %%M in ('"%ADB_CMD%" shell getprop ro.product.model') do echo Model:          %%M
for /f "tokens=*" %%V in ('"%ADB_CMD%" shell getprop ro.build.version.release') do echo Android Ver:    %%V
for /f "tokens=2 delims==" %%B in ('"%ADB_CMD%" shell dumpsys battery ^| findstr "level"') do echo Battery:        %%B%%
for /f "tokens=*" %%I in ('"%ADB_CMD%" shell "ip addr show wlan0 2>/nul | grep 'inet ' | cut -d'/' -f1 | cut -d' ' -f6"') do echo IP Address:     %%I
echo.
echo Storage Usage:
"%ADB_CMD%" shell df -h /sdcard
echo %C_SYS%=================================================%C_RESET%
echo.
goto INPUT_LOOP

:UNINSTALL_APP
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
set /p "PKG=Enter package name to uninstall: "
if not "!PKG!"=="" (
    echo %C_SYS%[INFO] Uninstalling !PKG!...%C_RESET%
    "%ADB_CMD%" uninstall "!PKG!"
)
echo.
goto INPUT_LOOP

:CLEAR_DATA
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
set /p "PKG=Enter package name to clear data: "
if not "!PKG!"=="" (
    echo %C_SYS%[INFO] Clearing data for !PKG!...%C_RESET%
    "%ADB_CMD%" shell pm clear "!PKG!"
)
echo.
goto INPUT_LOOP

:WIRELESS_ADB
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
echo %C_SYS%[INFO] Restarting ADB in TCP mode on port 5555...%C_RESET%
"%ADB_CMD%" tcpip 5555
echo %C_GREEN%[SUCCESS] You can now disconnect USB and connect via: adb connect <DEVICE_IP>:5555%C_RESET%
echo.
goto INPUT_LOOP

:REBOOT_DEVICE
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
echo %C_SYS%[INFO] Rebooting connected device...%C_RESET%
"%ADB_CMD%" reboot
echo.
goto INPUT_LOOP

:OPTIMIZE_DEVICE
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
echo %C_SYS%[INFO] Optimizing device...%C_RESET%
echo %C_SYS%[1/2] Trimming system and app caches...%C_RESET%
"%ADB_CMD%" shell pm trim-caches 999G >nul 2>&1
if !errorlevel! equ 0 (
    echo %C_GREEN%[SUCCESS] System cache trimmed successfully.%C_RESET%
) else (
    echo %C_ERR%[WARNING] Cache trim command restricted by device vendor.%C_RESET%
)
echo %C_SYS%[2/2] Running Storage TRIM (fstrim)...%C_RESET%
"%ADB_CMD%" shell sm fstrim >nul 2>&1
if !errorlevel! equ 0 (
    echo %C_GREEN%[SUCCESS] Flash storage TRIM completed.%C_RESET%
) else (
    echo %C_ERR%[WARNING] Storage TRIM skipped (requires Android 6.0+ or elevated permissions).%C_RESET%
)
echo.
echo %C_GREEN%[SUCCESS] Device storage optimized.%C_RESET%
goto INPUT_LOOP


:OPTIMIZE2_DEVICE
echo.
call :CHECK_DEVICE || goto INPUT_LOOP
goto INPUT_LOOP

:DRAG_N_DROP_TOOL
echo.
start .\data\watcher.bat
goto INPUT_LOOP

:HELP
echo.
goto SHOW_MENU

:CLEAR
echo.
cls
goto SHOW_MENU
