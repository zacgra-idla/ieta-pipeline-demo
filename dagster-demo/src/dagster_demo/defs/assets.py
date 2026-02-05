"""Extract assets that pull data from source APIs and write to DuckDB."""

from pathlib import Path

import duckdb
import pandas as pd

import dagster as dg

from dagster_demo.resources.sis_api import SISApiResource
from dagster_demo.resources.lms_api import LMSApiResource
from dagster_demo.resources.state_api import StateApiResource

# Path to the DuckDB database used by dbt
DUCKDB_PATH = Path(__file__).parent.parent.parent.parent.parent / "dbt-demo" / "dev.duckdb"


def _write_to_duckdb(df: pd.DataFrame, table_name: str, schema: str = "raw") -> None:
    """Write a DataFrame to DuckDB, creating the schema if needed."""
    with duckdb.connect(str(DUCKDB_PATH)) as conn:
        conn.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
        conn.execute(f"DROP TABLE IF EXISTS {schema}.{table_name}")
        conn.execute(f"CREATE TABLE {schema}.{table_name} AS SELECT * FROM df")


@dg.asset(
    group_name="extract",
    description="Extract attendance data from SIS",
)
def raw_attendance(sis_api: dg.ResourceParam["SISApiResource"]) -> dg.MaterializeResult:
    """Extract attendance data from the SIS API and load into DuckDB."""
    data = sis_api.get_all_attendance()
    df = pd.DataFrame(data)
    _write_to_duckdb(df, "attendance")
    return dg.MaterializeResult(
        metadata={
            "row_count": len(df),
            "columns": list(df.columns),
        }
    )


@dg.asset(
    group_name="extract",
    description="Extract gradebook data from LMS",
)
def raw_gradebook(lms_api: dg.ResourceParam["LMSApiResource"]) -> dg.MaterializeResult:
    """Extract gradebook data from the LMS API and load into DuckDB."""
    data = lms_api.get_all_gradebook()
    df = pd.DataFrame(data)
    _write_to_duckdb(df, "gradebook")
    return dg.MaterializeResult(
        metadata={
            "row_count": len(df),
            "columns": list(df.columns),
        }
    )


@dg.asset(
    group_name="extract",
    description="Extract ISAT data from State Reporting",
)
def raw_isat(state_api: dg.ResourceParam["StateApiResource"]) -> dg.MaterializeResult:
    """Extract ISAT data from the State Reporting API and load into DuckDB."""
    data = state_api.get_all_isat()
    df = pd.DataFrame(data)
    _write_to_duckdb(df, "isat")
    return dg.MaterializeResult(
        metadata={
            "row_count": len(df),
            "columns": list(df.columns),
        }
    )
