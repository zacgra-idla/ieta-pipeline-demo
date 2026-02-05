# IETA Pipeline Demo

A demonstration project integrating **Dagster** with **dbt** and **DuckDB** to build a star schema data warehouse from multiple source APIs.

## Overview

This project simulates an educational data pipeline that:
- Extracts data from 3 source APIs (SIS, LMS, State Reporting)
- Loads raw data into DuckDB
- Transforms data using dbt into a Kimball-style star schema
- Provides analytics-ready data marts

### Architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   SIS API   │  │   LMS API   │  │  State API  │
│  (port 8001)│  │  (port 8002)│  │  (port 8003)│
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │     Dagster     │
              │   (port 8888)   │
              │                 │
              │  Extract Assets │
              │        ↓        │
              │   dbt Models    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │     DuckDB      │
              │   (dev.duckdb)  │
              └─────────────────┘
```

### Data Model (Star Schema)

```
                      dim_student
                           │
          dim_assignment ──┼── dim_course
                │          │         │
                └────► fct_grade ◄───┘
                           │
                      dim_date
                           │
                      fct_attendance
                           │
                      fct_assessment
                           │
                   fct_student_snapshot
                           │
                    ┌──────┴──────┐
                    ▼             ▼
           mart_class_summary  mart_student_dashboard
```

## Prerequisites

Before running this project, you need:

| Tool | Version | Installation |
|------|---------|--------------|
| Git | Any | [git-scm.com](https://git-scm.com) |
| uv | Latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Python | 3.11+ | `uv python install 3.13` |

> **Note**: uv and Python install to your home directory (`~/.cargo/bin/` and `~/.local/share/uv/`), not this project folder.

## Quick Start

### macOS / Linux

```bash
# 1. Check prerequisites and install project dependencies
./install.sh

# 2. Start all services
./dev.sh

# 3. Open Dagster UI
open http://localhost:8888
```

### Windows (PowerShell)

```powershell
# 1. Check prerequisites and install project dependencies
powershell -ExecutionPolicy Bypass -File install.ps1

# 2. Start all services
powershell -ExecutionPolicy Bypass -File dev.ps1

# 3. Open Dagster UI
Start-Process http://localhost:8888
```

## Usage

### Running the Pipeline

1. Open Dagster UI at http://localhost:8888
2. Navigate to **Assets**
3. Click **Materialize all** to run the full pipeline:
   - Extract assets pull data from APIs → DuckDB `raw` schema
   - dbt models transform data through staging → intermediate → dimensions → facts → marts

### Browsing the Database

Use DuckDB's built-in UI to explore the data:

```bash
duckdb -ui dbt-demo/dev.duckdb
```

### Testing the APIs

```bash
./test_apis.sh

# Or manually:
curl http://localhost:8001/attendance?limit=1  # SIS
curl http://localhost:8002/gradebook?limit=1   # LMS
curl http://localhost:8003/isat?limit=1        # State
```

## Project Structure

```
.
├── api/                          # Source APIs (FastAPI)
│   ├── sis.py                    # Student Information System (attendance)
│   ├── lms.py                    # Learning Management System (gradebook)
│   ├── state.py                  # State Reporting (ISAT scores)
│   └── data/                     # Parquet files for API data
│
├── dagster-demo/                 # Dagster project
│   └── src/dagster_demo/
│       ├── definitions.py        # Main definitions (resources, executor)
│       ├── resources/            # API clients, DuckDB resource
│       └── defs/
│           ├── assets.py         # Extract assets (raw_*)
│           └── dbt_project/      # DbtProjectComponent config
│
├── dbt-demo/                     # dbt project
│   ├── models/
│   │   ├── staging/              # stg_* (views)
│   │   ├── intermediate/         # int_* (unpivoted views)
│   │   ├── dimensions/           # dim_* (tables)
│   │   ├── facts/                # fct_* (tables)
│   │   └── marts/                # mart_* (tables)
│   ├── profiles.yml              # DuckDB connection
│   └── dbt_project.yml           # dbt configuration
│
├── install.sh / install.ps1      # Setup scripts
├── dev.sh / dev.ps1              # Development server scripts
├── cleanup.sh / cleanup.ps1      # Cleanup scripts
└── test_apis.sh                  # API test script
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| SIS API | 8001 | Attendance data |
| LMS API | 8002 | Gradebook data |
| State API | 8003 | ISAT assessment data |
| Dagster | 8888 | Orchestration UI |

## Data Marts

### mart_class_summary
Class-level aggregations per course/section:
- Total students
- Lowest/highest/average grade
- Grade distribution (A/B/C/D/F counts)

### mart_student_dashboard
Student-level metrics aligned with the IETA Instructions:
- Checkpoint grades (Week 3, 6, 9)
- Trend status (Improving/Declining/Failing/Fluctuating)
- Missing assignments count and percentage
- Attendance metrics
- ISAT scores
- Risk indicators

## Cleanup

To remove all generated files (keeps source code):

```bash
# macOS / Linux
./cleanup.sh

# Windows
powershell -ExecutionPolicy Bypass -File cleanup.ps1
```

This removes:
- `.dagster_home/` - Dagster state
- `*/. venv/` - Virtual environments
- `dbt-demo/dev.duckdb` - Database
- `dbt-demo/target/` - dbt artifacts

> **Note**: uv and Python in your home directory are NOT removed.

## Troubleshooting

### DuckDB Lock Error
If you see "Could not set lock on file":
1. Stop all services (Ctrl+C in dev.sh terminal)
2. Close any database browsers (DBeaver, etc.)
3. Run: `lsof | grep dev.duckdb` to find holding processes
4. Restart with `./dev.sh`

### dbt Models Fail with "Table does not exist"
The extract assets must run before dbt models. In Dagster UI:
1. First materialize the **extract** group
2. Then materialize the **dbt** models

### Cache Issues
Clear the DbtProjectComponent cache:
```bash
rm -rf dagster-demo/src/dagster_demo/defs/.local_defs_state/
```

## License

MIT
