#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up development environment...${NC}"

# Sync dependencies for both projects
echo -e "${GREEN}Syncing API dependencies...${NC}"
cd ./api
uv sync
cd ..
echo -e "${GREEN}Syncing Dagster dependencies...${NC}"
cd ./dagster-demo
uv sync
cd ..

# Start services
echo -e "${GREEN}Starting API server on http://localhost:8000...${NC}"
cd ./api
uv run uvicorn main:app --port 8000 &
API_PID=$!
cd ..
echo -e "${GREEN}Starting Dagster dev server...${NC}"
cd ./dagster-demo
uv run dg dev &
DG_PID=$!

echo -e "${BLUE}Services started:${NC}"
echo "  - API: http://localhost:8000 (PID: $API_PID)"
echo "  - API docs: http://localhost:8000/docs"
echo "  - Dagster: (PID: $DG_PID) - see output above for URL"
echo ""
echo "Press Ctrl+C to stop all services"

# Trap Ctrl+C to kill both processes
trap "echo 'Stopping services...'; kill $API_PID $DG_PID 2>/dev/null; exit 0" SIGINT SIGTERM

# Wait for processes
wait
