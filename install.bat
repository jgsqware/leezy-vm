@echo off
REM Leezy VM Windows Installer Batch Wrapper
REM This batch file ensures PowerShell runs with correct permissions

echo =====================================
echo    Leezy VM - Windows Installer
echo =====================================
echo.
echo This installer will:
echo   - Install Git, VirtualBox, and Vagrant
echo   - Clone the Leezy VM repository
echo   - Setup and start the VM
echo.
echo Press any key to continue or CTRL+C to cancel...
pause >nul

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] This installer requires Administrator privileges.
    echo.
    echo Please right-click on install.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Download and execute the PowerShell script
echo.
echo Downloading installation script...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $script = (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jgsqware/leezy-vm/main/install-windows.ps1'); Invoke-Expression $script}"

echo.
echo =====================================
echo Installation process completed!
echo =====================================
echo.
pause