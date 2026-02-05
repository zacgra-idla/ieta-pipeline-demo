"""Extract assets that pull data from the IETA API and write to DuckDB."""

from pathlib import Path

import duckdb
import pandas as pd

import dagster as dg

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
    description="Extract student/ISAT data from the IETA API",
)
def raw_isat(ieta_api: dg.ResourceParam["IETAApiResource"]) -> dg.MaterializeResult:
    """Extract ISAT data from the API and load into DuckDB."""
    data = ieta_api.get_all_isat()
    df = pd.DataFrame(data)
    _write_to_duckdb(df, "isat")
    return dg.MaterializeResult(
        metadata={
            "row_count": len(df),
            "columns": list(df.columns),
        }
    )


@dg.asset(
    group_name="extract",
    description="Extract attendance data from the IETA API",
)
def raw_attendance(ieta_api: dg.ResourceParam["IETAApiResource"]) -> dg.MaterializeResult:
    """Extract attendance data from the API and load into DuckDB."""
    data = ieta_api.get_all_attendance()
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
    description="Extract gradebook data from the IETA API",
)
def raw_gradebook(ieta_api: dg.ResourceParam["IETAApiResource"]) -> dg.MaterializeResult:
    """Extract gradebook data from the API and load into DuckDB."""
    data = ieta_api.get_all_gradebook()
    df = pd.DataFrame(data)
    _write_to_duckdb(df, "gradebook")
    return dg.MaterializeResult(
        metadata={
            "row_count": len(df),
            "columns": list(df.columns),
        }
    )
