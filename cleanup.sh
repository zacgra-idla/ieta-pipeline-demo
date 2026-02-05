#!/bin/bash

# IETA Pipeline Demo - Cleanup Script (macOS/Linux)
# Removes all generated files within the project directory
# For Windows, use: powershell -ExecutionPolicy Bypass -File cleanup.ps1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}This will remove all generated project files:${NC}"
echo ""
echo "  - .dagster_home/     (Dagster state)"
echo "  - api/.venv/         (API dependencies)"
echo "  - dagster-demo/.venv/ (Dagster dependencies)"
echo "  - dbt-demo/.venv/    (dbt dependencies)"
echo "  - dbt-demo/dev.duckdb (database)"
echo "  - dagster-demo/.../DbtProjectComponent cache"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Cleaning up..."

    rm -rf .dagster_home && echo -e "${GREEN}✓${NC} Removed .dagster_home"
    rm -rf api/.venv && echo -e "${GREEN}✓${NC} Removed api/.venv"
    rm -rf dagster-demo/.venv && echo -e "${GREEN}✓${NC} Removed dagster-demo/.venv"
    rm -rf dbt-demo/.venv && echo -e "${GREEN}✓${NC} Removed dbt-demo/.venv"
    rm -f dbt-demo/dev.duckdb && echo -e "${GREEN}✓${NC} Removed dbt-demo/dev.duckdb"
    rm -f dbt-demo/dev.duckdb.wal && echo -e "${GREEN}✓${NC} Removed dbt-demo/dev.duckdb.wal"
    rm -rf dagster-demo/src/dagster_demo/defs/.local_defs_state && echo -e "${GREEN}✓${NC} Removed DbtProjectComponent cache"
    rm -rf dbt-demo/target && echo -e "${GREEN}✓${NC} Removed dbt-demo/target"
    rm -rf dbt-demo/logs && echo -e "${GREEN}✓${NC} Removed dbt-demo/logs"

    echo ""
    echo -e "${GREEN}Cleanup complete!${NC}"
    echo ""
    echo "Note: uv and Python installations in your home directory were NOT removed."
    echo "To remove those manually:"
    echo "  rm -rf ~/.cargo/bin/uv ~/.local/share/uv ~/.cache/uv"
else
    echo "Cleanup cancelled."
fi
