# IETA Pipeline Demo - Cleanup Script (Windows)
# Removes all generated files within the project directory

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "This will remove all generated project files:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  - .dagster_home\     (Dagster state)"
Write-Host "  - api\.venv\         (API dependencies)"
Write-Host "  - dagster-demo\.venv\ (Dagster dependencies)"
Write-Host "  - dbt-demo\.venv\    (dbt dependencies)"
Write-Host "  - dbt-demo\dev.duckdb (database)"
Write-Host "  - dagster-demo\...\DbtProjectComponent cache"
Write-Host ""

$confirm = Read-Host "Continue? (y/N)"

if ($confirm -eq "y" -or $confirm -eq "Y") {
    Write-Host ""
    Write-Host "Cleaning up..."

    $items = @(
        @{Path=".dagster_home"; Name=".dagster_home"},
        @{Path="api\.venv"; Name="api\.venv"},
        @{Path="dagster-demo\.venv"; Name="dagster-demo\.venv"},
        @{Path="dbt-demo\.venv"; Name="dbt-demo\.venv"},
        @{Path="dbt-demo\dev.duckdb"; Name="dbt-demo\dev.duckdb"},
        @{Path="dbt-demo\dev.duckdb.wal"; Name="dbt-demo\dev.duckdb.wal"},
        @{Path="dagster-demo\src\dagster_demo\defs\.local_defs_state"; Name="DbtProjectComponent cache"},
        @{Path="dbt-demo\target"; Name="dbt-demo\target"},
        @{Path="dbt-demo\logs"; Name="dbt-demo\logs"}
    )

    foreach ($item in $items) {
        $fullPath = Join-Path $ScriptDir $item.Path
        if (Test-Path $fullPath) {
            Remove-Item -Recurse -Force $fullPath -ErrorAction SilentlyContinue
            Write-Host "[OK] Removed $($item.Name)" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: uv and Python installations in your user profile were NOT removed."
    Write-Host "To remove those manually:"
    Write-Host "  Remove-Item -Recurse -Force ~\.cargo\bin\uv*, ~\AppData\Local\uv, ~\AppData\Roaming\uv"
} else {
    Write-Host "Cleanup cancelled."
}
