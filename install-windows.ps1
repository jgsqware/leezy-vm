#Requires -RunAsAdministrator
# Leezy VM Windows Installation Script
# This script installs all dependencies and sets up the VM on Windows

param(
    [string]$TailscaleAuthKey = "",
    [string]$InstallPath = "$env:USERPROFILE\leezy-vm",
    [switch]$SkipVMStart = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Leezy VM - Windows Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Function to refresh PATH
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/7] Checking and installing Chocolatey..." -ForegroundColor Green
if (-not (Test-Command choco)) {
    Write-Host "  Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Refresh-Path
} else {
    Write-Host "  Chocolatey already installed" -ForegroundColor Gray
}

Write-Host "[2/7] Installing Git..." -ForegroundColor Green
if (-not (Test-Command git)) {
    choco install git -y --no-progress | Out-Null
    Refresh-Path
    Write-Host "  Git installed successfully" -ForegroundColor Gray
} else {
    Write-Host "  Git already installed" -ForegroundColor Gray
}

Write-Host "[3/7] Installing VirtualBox..." -ForegroundColor Green
if (-not (Test-Command VBoxManage)) {
    Write-Host "  This may take a few minutes..." -ForegroundColor Yellow
    choco install virtualbox -y --no-progress | Out-Null
    Refresh-Path
    Write-Host "  VirtualBox installed successfully" -ForegroundColor Gray
} else {
    Write-Host "  VirtualBox already installed" -ForegroundColor Gray
}

Write-Host "[4/7] Installing Vagrant..." -ForegroundColor Green
if (-not (Test-Command vagrant)) {
    Write-Host "  This may take a few minutes..." -ForegroundColor Yellow
    choco install vagrant -y --no-progress | Out-Null
    Refresh-Path
    Write-Host "  Vagrant installed successfully" -ForegroundColor Gray
} else {
    Write-Host "  Vagrant already installed" -ForegroundColor Gray
}

Write-Host "[5/7] Cloning Leezy VM repository..." -ForegroundColor Green
if (Test-Path $InstallPath) {
    Write-Host "  Repository already exists at $InstallPath" -ForegroundColor Yellow
    $response = Read-Host "  Do you want to update it? (y/n)"
    if ($response -eq 'y') {
        Set-Location $InstallPath
        git pull origin main 2>$null
        Write-Host "  Repository updated" -ForegroundColor Gray
    }
} else {
    git clone https://github.com/jgsqware/leezy-vm.git $InstallPath 2>$null
    Write-Host "  Repository cloned to $InstallPath" -ForegroundColor Gray
}

Set-Location $InstallPath

Write-Host "[6/7] Setting up configuration..." -ForegroundColor Green
# Create .env file from template if it doesn't exist
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "  Created .env file from template" -ForegroundColor Gray
        
        # Add Tailscale auth key if provided
        if ($TailscaleAuthKey) {
            $envContent = Get-Content ".env"
            $envContent = $envContent -replace "TAILSCALE_AUTH_KEY=", "TAILSCALE_AUTH_KEY=$TailscaleAuthKey"
            Set-Content ".env" $envContent
            Write-Host "  Added Tailscale auth key to .env" -ForegroundColor Gray
        } else {
            Write-Host "" -ForegroundColor Yellow
            Write-Host "  ⚠️  No Tailscale auth key provided" -ForegroundColor Yellow
            Write-Host "  Edit $InstallPath\.env to add your TAILSCALE_AUTH_KEY" -ForegroundColor Yellow
            Write-Host "  Get your key from: https://login.tailscale.com/admin/settings/keys" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  .env file already exists" -ForegroundColor Gray
}

Write-Host "[7/7] Starting the VM..." -ForegroundColor Green
if (-not $SkipVMStart) {
    Write-Host "  Running 'vagrant up'..." -ForegroundColor Yellow
    Write-Host "  This may take several minutes on first run..." -ForegroundColor Yellow
    
    try {
        vagrant up
        Write-Host "" -ForegroundColor Green
        Write-Host "✅ Installation complete!" -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
        
        Write-Host "VM is now running. You can:" -ForegroundColor Cyan
        Write-Host "  - SSH into it: vagrant ssh" -ForegroundColor White
        Write-Host "  - Stop it: vagrant halt" -ForegroundColor White
        Write-Host "  - Check status: vagrant status" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "TinyProxy is available at: http://localhost:8888" -ForegroundColor Cyan
    } catch {
        Write-Host "  Failed to start VM. Please check the error above." -ForegroundColor Red
        Write-Host "  You can try running 'vagrant up' manually from $InstallPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "" -ForegroundColor Green
    Write-Host "✅ Installation complete!" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "To start the VM, navigate to $InstallPath and run:" -ForegroundColor Cyan
    Write-Host "  vagrant up" -ForegroundColor White
}

Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Gray
Write-Host "=====================================" -ForegroundColor Cyan