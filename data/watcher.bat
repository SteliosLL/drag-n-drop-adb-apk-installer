@echo off
setlocal enabledelayedexpansion

:: Enable ANSI color codes
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: Define ANSI Color Palette
set "C_RESET=%ESC%[0m"
set "C_SYS=%ESC%[36m"      :: Cyan
set "C_DEV=%ESC%[33m"      :: Yellow
set "C_APK=%ESC%[32m"      :: Green
set "C_FILE=%ESC%[35m"     :: Magenta
set "C_ERR=%ESC%[31m"      :: Red
set "C_GRAY=%ESC%[90m"     :: Bright Black / Gray

:: Resolve absolute path to root directory 
for %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI"

set "DATA_DIR=%~dp0"
set "ADB_CMD=%DATA_DIR%adb.exe"

:: Fallback to system PATH if local adb.exe doesn't exist in data\
if not exist "%ADB_CMD%" set "ADB_CMD=adb"

:: Set absolute target folders in the root directory
set "APK_DIR=%ROOT_DIR%\apks_to_install"
set "APK_DEST=%ROOT_DIR%\apks_to_install\installed"

set "FILE_DIR=%ROOT_DIR%\files_to_copy"
set "FILE_DEST=%ROOT_DIR%\files_to_copy\copied"

:: Scan interval in seconds
set CHECK_INTERVAL=3

:: State tracker for device connection
set "PREV_STATE=unknown"

:: Auto-create local directories in root if missing
if not exist "%APK_DIR%" mkdir "%APK_DIR%"
if not exist "%APK_DEST%" mkdir "%APK_DEST%"
if not exist "%FILE_DIR%" mkdir "%FILE_DIR%"
if not exist "%FILE_DEST%" mkdir "%FILE_DEST%"

cls
echo %C_SYS%=========================================================%C_RESET%
echo %C_RESET% %C_APK%    --DRAG 'N DROP APK INSTALLER AND FILE COPIER--
echo.
echo %C_RESET%   Root Dir: %ROOT_DIR%
echo %C_SYS%=========================================================%C_RESET%
echo.

:WATCH_LOOP

:: count pending queue and set title
set "APK_COUNT=0"
for %%F in ("%APK_DIR%\*.apk") do set /a APK_COUNT+=1

set "FILE_COUNT=0"
for /f "delims=" %%F in ('dir /b /a:-d "%FILE_DIR%\*" 2^>nul') do set /a FILE_COUNT+=1

title Drag 'n Drop Console ^| Queue: !APK_COUNT! APKs, !FILE_COUNT! Files

:: -------Check device connection ------
"%ADB_CMD%" devices | findstr /R /C:"device$" >nul
if !errorlevel! equ 0 (
    if "!PREV_STATE!" neq "connected" (
        echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_DEV%[DEVICE]%C_RESET% Device connected.
        :: Ensure the custom adb_copied_files folder exists on the Android device
        "%ADB_CMD%" shell "mkdir -p /sdcard/adb_copied_files" >nul 2>&1
        set "PREV_STATE=connected"
    )
    set "DEVICE_READY=1"
) else (
    if "!PREV_STATE!" neq "disconnected" (
        echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_DEV%[DEVICE]%C_RESET% No device found.
        set "PREV_STATE=disconnected"
    )
    set "DEVICE_READY=0"
)

:: --------Process APKs-------
if !DEVICE_READY! equ 1 (
    for %%F in ("%APK_DIR%\*.apk") do (
        set "FILE_NAME=%%~nxF"
        set "FULL_PATH=%%~fF"
        
        REM Test file lock by attempting a safe rename-to-self
        (ren "!FULL_PATH!" "!FILE_NAME!") 2>nul
        if !errorlevel! equ 0 (
            echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_APK%[APK]%C_RESET% Installing !FILE_NAME!...
            
            "%ADB_CMD%" install -r -t "!FULL_PATH!" >nul 2>&1
            
            if !errorlevel! equ 0 (
                echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_APK%[APK]%C_RESET% Installed: !FILE_NAME!
                move /y "!FULL_PATH!" "%APK_DEST%\" >nul 2>&1
            ) else (
                echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_ERR%[ERROR]%C_RESET% Failed to install: !FILE_NAME!
            )
        )
    )
)

:: -----Process general files -----
for /f "delims=" %%F in ('dir /b /a:-d "%FILE_DIR%\*" 2^>nul') do (
    set "FILE_NAME=%%F"
    set "FULL_PATH=%FILE_DIR%\%%F"
    
    REM Test file lock by attempting a safe rename-to-self
    (ren "!FULL_PATH!" "!FILE_NAME!") 2>nul
    if !errorlevel! equ 0 (
        if !DEVICE_READY! equ 1 (
            echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_FILE%[FILE]%C_RESET% Copying !FILE_NAME! to device...
            
            REM Push file to Android /sdcard/adb_copied_files/
            "%ADB_CMD%" push "!FULL_PATH!" "/sdcard/adb_copied_files/" >nul 2>&1
            
            if !errorlevel! equ 0 (
                echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_FILE%[FILE]%C_RESET% Copied to /sdcard/adb_copied_files/
                move /y "!FULL_PATH!" "%FILE_DEST%\" >nul 2>&1
            ) else (
                echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_ERR%[ERROR]%C_RESET% Failed to copy to device: !FILE_NAME!
            )
        ) else (
            echo %C_GRAY%[%time:~0,8%]%C_RESET% %C_FILE%[FILE]%C_RESET% Moving !FILE_NAME! to local copied folder...
            move /y "!FULL_PATH!" "%FILE_DEST%\" >nul 2>&1
        )
    )
)

:: Wait for next cycle
timeout /t %CHECK_INTERVAL% /nobreak >nul
goto WATCH_LOOP