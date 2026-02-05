#!/bin/bash
set -e

# IETA Pipeline Demo - Installation Script (macOS/Linux)
# For Windows, use: powershell -ExecutionPolicy Bypass -File install.ps1
#
# This script only CHECKS for prerequisites and does NOT install anything
# outside the project directory. All project files stay within this folder.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Checking prerequisites for IETA Pipeline Demo...${NC}"
echo ""

MISSING_DEPS=false

# Check for Python 3.11+
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 11 ]; then
            echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION"
            return 0
        else
            echo -e "${YELLOW}!${NC} Python $PYTHON_VERSION (3.11+ recommended)"
            return 0
        fi
    else
        echo -e "${RED}✗${NC} Python 3.11+ not found"
        MISSING_DEPS=true
        return 1
    fi
}

# Check for uv
check_uv() {
    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version | head -n1)
        echo -e "${GREEN}✓${NC} $UV_VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} uv not found"
        MISSING_DEPS=true
        return 1
    fi
}

# Check for git
check_git() {
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        echo -e "${GREEN}✓${NC} git $GIT_VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} git not found"
        MISSING_DEPS=true
        return 1
    fi
}

# Run checks
echo "Checking dependencies:"
echo ""

check_git || true
check_python || true
check_uv || true

echo ""

if [ "$MISSING_DEPS" = true ]; then
    echo -e "${RED}Missing dependencies detected.${NC}"
    echo ""
    echo "Please install the following manually:"
    echo ""
    if ! command -v git &> /dev/null; then
        echo "  Git:"
        echo "    macOS:  brew install git"
        echo "    Linux:  sudo apt install git  (or yum/dnf)"
        echo ""
    fi
    if ! command -v uv &> /dev/null; then
        echo "  uv (Python package manager):"
        echo "    curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "    (installs to ~/.cargo/bin/)"
        echo ""
    fi
    if ! command -v python3 &> /dev/null; then
        echo "  Python 3.11+:"
        echo "    After installing uv: uv python install 3.13"
        echo "    (installs to ~/.local/share/uv/python/)"
        echo ""
    fi
    echo -e "${YELLOW}Note: uv and Python install to your home directory, not this project.${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}All prerequisites installed!${NC}"
echo ""

# Sync project dependencies (creates .venv inside project dirs)
echo -e "${BLUE}Setting up project dependencies...${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing API dependencies..."
cd "$SCRIPT_DIR/api"
uv sync
echo -e "${GREEN}✓${NC} api/.venv created"

echo "Installing Dagster dependencies..."
cd "$SCRIPT_DIR/dagster-demo"
uv sync
echo -e "${GREEN}✓${NC} dagster-demo/.venv created"

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${BLUE}All project files are contained within:${NC}"
echo "  $(pwd)/.."
echo ""
echo -e "${BLUE}To clean up after demo:${NC}"
echo "  rm -rf .dagster_home api/.venv dagster-demo/.venv dbt-demo/.venv dbt-demo/dev.duckdb"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Run ${GREEN}./dev.sh${NC} to start the development environment"
echo "  2. Open ${GREEN}http://localhost:8888${NC} for Dagster UI"
echo "  3. APIs available at ports 8001 (SIS), 8002 (LMS), 8003 (State)"
echo ""
