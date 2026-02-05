# IETA Pipeline Demo - Windows Installation Script
# Run with: powershell -ExecutionPolicy Bypass -File install.ps1
#
# This script only CHECKS for prerequisites and does NOT install anything
# outside the project directory. All project files stay within this folder.

$ErrorActionPreference = "Stop"

Write-Host "Checking prerequisites for IETA Pipeline Demo..." -ForegroundColor Blue
Write-Host ""

$missingDeps = $false

# Check for Python 3.11+
function Check-Python {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 11) {
                Write-Host "[OK] Python $major.$minor" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] Python $major.$minor (3.11+ recommended)" -ForegroundColor Yellow
                return $true
            }
        }
    } catch {
        Write-Host "[X] Python 3.11+ not found" -ForegroundColor Red
        $script:missingDeps = $true
        return $false
    }
}

# Check for uv
function Check-Uv {
    try {
        $uvVersion = uv --version 2>&1
        Write-Host "[OK] $uvVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[X] uv not found" -ForegroundColor Red
        $script:missingDeps = $true
        return $false
    }
}

# Check for git
function Check-Git {
    try {
        $gitVersion = git --version 2>&1
        Write-Host "[OK] $gitVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[X] git not found" -ForegroundColor Red
        $script:missingDeps = $true
        return $false
    }
}

# Run checks
Write-Host "Checking dependencies:"
Write-Host ""

Check-Git | Out-Null
Check-Python | Out-Null
Check-Uv | Out-Null

Write-Host ""

if ($missingDeps) {
    Write-Host "Missing dependencies detected." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install the following manually:"
    Write-Host ""

    try { git --version 2>&1 | Out-Null } catch {
        Write-Host "  Git:"
        Write-Host "    Download from: https://git-scm.com/download/win"
        Write-Host ""
    }

    try { uv --version 2>&1 | Out-Null } catch {
        Write-Host "  uv (Python package manager):"
        Write-Host "    irm https://astral.sh/uv/install.ps1 | iex"
        Write-Host "    (installs to %USERPROFILE%\.cargo\bin\)"
        Write-Host ""
    }

    try { python --version 2>&1 | Out-Null } catch {
        Write-Host "  Python 3.11+:"
        Write-Host "    After installing uv: uv python install 3.13"
        Write-Host "    (installs to %APPDATA%\uv\python\)"
        Write-Host ""
    }

    Write-Host "Note: uv and Python install to your user profile, not this project." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "All prerequisites installed!" -ForegroundColor Green
Write-Host ""

# Sync project dependencies (creates .venv inside project dirs)
Write-Host "Setting up project dependencies..." -ForegroundColor Blue
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing API dependencies..."
Push-Location (Join-Path $ScriptDir "api")
uv sync
Pop-Location
Write-Host "[OK] api\.venv created" -ForegroundColor Green

Write-Host "Installing Dagster dependencies..."
Push-Location (Join-Path $ScriptDir "dagster-demo")
uv sync
Pop-Location
Write-Host "[OK] dagster-demo\.venv created" -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "All project files are contained within:" -ForegroundColor Blue
Write-Host "  $ScriptDir"
Write-Host ""
Write-Host "To clean up after demo:" -ForegroundColor Blue
Write-Host "  Remove-Item -Recurse -Force .dagster_home, api\.venv, dagster-demo\.venv, dbt-demo\.venv, dbt-demo\dev.duckdb"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "  1. Run " -NoNewline; Write-Host ".\dev.ps1" -ForegroundColor Green -NoNewline; Write-Host " to start the development environment"
Write-Host "  2. Open " -NoNewline; Write-Host "http://localhost:8888" -ForegroundColor Green -NoNewline; Write-Host " for Dagster UI"
Write-Host "  3. APIs available at ports 8001 (SIS), 8002 (LMS), 8003 (State)"
Write-Host ""
