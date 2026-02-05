# IETA Pipeline Demo - Windows Development Script
# Run with: powershell -ExecutionPolicy Bypass -File dev.ps1

$ErrorActionPreference = "Stop"

Write-Host "Setting up development environment..." -ForegroundColor Blue

# Set DAGSTER_HOME to keep state in the repo
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:DAGSTER_HOME = Join-Path $ScriptDir ".dagster_home"
New-Item -ItemType Directory -Force -Path $env:DAGSTER_HOME | Out-Null
Write-Host "DAGSTER_HOME set to $env:DAGSTER_HOME" -ForegroundColor Green

# Set DuckDB path so dbt uses the same database as extract assets
$env:DBT_DUCKDB_PATH = Join-Path $ScriptDir "dbt-demo\dev.duckdb"
Write-Host "DBT_DUCKDB_PATH set to $env:DBT_DUCKDB_PATH" -ForegroundColor Green

# Sync dependencies
Write-Host "Syncing API dependencies..." -ForegroundColor Green
Push-Location (Join-Path $ScriptDir "api")
uv sync
Pop-Location

Write-Host "Syncing Dagster dependencies..." -ForegroundColor Green
Push-Location (Join-Path $ScriptDir "dagster-demo")
uv sync
Pop-Location

# Start services as background jobs
Write-Host "Starting SIS API on http://localhost:8001..." -ForegroundColor Green
$sisJob = Start-Job -ScriptBlock {
    param($dir)
    Set-Location $dir
    uv run uvicorn sis:app --port 8001 --reload
} -ArgumentList (Join-Path $ScriptDir "api")

Write-Host "Starting LMS API on http://localhost:8002..." -ForegroundColor Green
$lmsJob = Start-Job -ScriptBlock {
    param($dir)
    Set-Location $dir
    uv run uvicorn lms:app --port 8002 --reload
} -ArgumentList (Join-Path $ScriptDir "api")

Write-Host "Starting State API on http://localhost:8003..." -ForegroundColor Green
$stateJob = Start-Job -ScriptBlock {
    param($dir)
    Set-Location $dir
    uv run uvicorn state:app --port 8003 --reload
} -ArgumentList (Join-Path $ScriptDir "api")

Write-Host "Starting Dagster dev server on http://localhost:8888..." -ForegroundColor Green
$dagsterJob = Start-Job -ScriptBlock {
    param($dir, $dagsterHome, $duckdbPath)
    $env:DAGSTER_HOME = $dagsterHome
    $env:DBT_DUCKDB_PATH = $duckdbPath
    Set-Location $dir
    uv run dg dev --port 8888
} -ArgumentList (Join-Path $ScriptDir "dagster-demo"), $env:DAGSTER_HOME, $env:DBT_DUCKDB_PATH

Write-Host ""
Write-Host "Services started:" -ForegroundColor Blue
Write-Host "  - SIS API: http://localhost:8001 (Job: $($sisJob.Id))"
Write-Host "  - LMS API: http://localhost:8002 (Job: $($lmsJob.Id))"
Write-Host "  - State API: http://localhost:8003 (Job: $($stateJob.Id))"
Write-Host "  - Dagster: http://localhost:8888 (Job: $($dagsterJob.Id))"
Write-Host ""
Write-Host "To browse the database:" -ForegroundColor Blue
Write-Host "  duckdb -ui " -NoNewline; Write-Host "$env:DBT_DUCKDB_PATH" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

# Wait and handle Ctrl+C
try {
    while ($true) {
        # Check if any jobs failed
        $jobs = @($sisJob, $lmsJob, $stateJob, $dagsterJob)
        foreach ($job in $jobs) {
            if ($job.State -eq "Failed") {
                Write-Host "Job $($job.Id) failed. Output:" -ForegroundColor Red
                Receive-Job $job
            }
        }
        Start-Sleep -Seconds 2
    }
} finally {
    Write-Host "Stopping services..." -ForegroundColor Yellow
    Stop-Job $sisJob, $lmsJob, $stateJob, $dagsterJob -ErrorAction SilentlyContinue
    Remove-Job $sisJob, $lmsJob, $stateJob, $dagsterJob -Force -ErrorAction SilentlyContinue
    Write-Host "All services stopped." -ForegroundColor Green
}
