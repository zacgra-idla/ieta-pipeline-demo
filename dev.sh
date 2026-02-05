#!/bin/bash
set -e

# IETA Pipeline Demo - Development Script (macOS/Linux)
# For Windows, use: powershell -ExecutionPolicy Bypass -File dev.ps1

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up development environment...${NC}"

# Set DAGSTER_HOME to keep state in the repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DAGSTER_HOME="$SCRIPT_DIR/.dagster_home"
mkdir -p "$DAGSTER_HOME"
echo -e "${GREEN}DAGSTER_HOME set to $DAGSTER_HOME${NC}"

# Set DuckDB path so dbt uses the same database as extract assets
export DBT_DUCKDB_PATH="$SCRIPT_DIR/dbt-demo/dev.duckdb"
echo -e "${GREEN}DBT_DUCKDB_PATH set to $DBT_DUCKDB_PATH${NC}"

# Sync dependencies for both projects
echo -e "${GREEN}Syncing API dependencies...${NC}"
cd ./api
uv sync
cd ..
echo -e "${GREEN}Syncing Dagster dependencies...${NC}"
cd ./dagster-demo
uv sync
cd ..

# Start API services with --reload for development
echo -e "${GREEN}Starting SIS API on http://localhost:8001...${NC}"
cd ./api
uv run uvicorn sis:app --port 8001 --reload &
SIS_PID=$!

echo -e "${GREEN}Starting LMS API on http://localhost:8002...${NC}"
uv run uvicorn lms:app --port 8002 --reload &
LMS_PID=$!

echo -e "${GREEN}Starting State API on http://localhost:8003...${NC}"
uv run uvicorn state:app --port 8003 --reload &
STATE_PID=$!
cd ..

echo -e "${GREEN}Starting Dagster dev server on http://localhost:8888...${NC}"
cd ./dagster-demo
uv run dg dev --port 8888 &
DG_PID=$!

echo -e "${BLUE}Services started:${NC}"
echo "  - SIS API: http://localhost:8001 (PID: $SIS_PID)"
echo "  - LMS API: http://localhost:8002 (PID: $LMS_PID)"
echo "  - State API: http://localhost:8003 (PID: $STATE_PID)"
echo "  - Dagster: http://localhost:8888 (PID: $DG_PID)"
echo ""
echo -e "${BLUE}To browse the database:${NC}"
echo -e "  duckdb -ui ${GREEN}$DBT_DUCKDB_PATH${NC}"
echo ""
echo "Press Ctrl+C to stop all services"

# Trap Ctrl+C to kill all processes
trap "echo 'Stopping services...'; kill $SIS_PID $LMS_PID $STATE_PID $DG_PID 2>/dev/null; exit 0" SIGINT SIGTERM

# Wait for processes
wait
