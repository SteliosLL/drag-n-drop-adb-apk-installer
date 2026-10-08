@echo off
setlocal

set "DATA_DIR=%~dp0data"

:: Ensure data directory exists
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

:: Launch Watcher (Left Side)
start "Watcher Console" cmd /k "%DATA_DIR%\watcher.bat"

:: Launch Control Console (Right Side)
start "Control Console" cmd /k "%DATA_DIR%\console_input.bat"

:: Align both windows side-by-side
powershell -Command "$w=Add-Type -memberDefinition '[DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int h, bool r);' -name W -passthru; $screen=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea; Start-Sleep -MilliSeconds 500; $h1=(Get-Process | Where-Object {$_.MainWindowTitle -eq 'Watcher Console'}).MainWindowHandle; $h2=(Get-Process | Where-Object {$_.MainWindowTitle -eq 'Control Console'}).MainWindowHandle; $w::MoveWindow($h1, 0, 0, [int]($screen.Width/2), $screen.Height, $true); $w::MoveWindow($h2, [int]($screen.Width/2), 0, [int]($screen.Width/2), $screen.Height, $true);" >nul 2>&1