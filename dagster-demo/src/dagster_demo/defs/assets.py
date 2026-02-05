"""Extract assets that pull data from source APIs and write to DuckDB."""

import dagster as dg

from dagster_demo.resources.duckdb import DuckDBResource
from dagster_demo.resources.sis_api import SISApiResource
from dagster_demo.resources.lms_api import LMSApiResource
from dagster_demo.resources.state_api import StateApiResource

import pandas as pd

# Tag to serialize DuckDB write operations
DUCKDB_WRITE_TAG = {"dagster/concurrency_key": "duckdb_write"}


@dg.asset(
    group_name="extract",
    description="Extract attendance data from SIS",
    tags=DUCKDB_WRITE_TAG,
)
def raw_attendance(
    sis_api: dg.ResourceParam[SISApiResource],
    duckdb: dg.ResourceParam[DuckDBResource],
) -> dg.MaterializeResult:
    """Extract attendance data from the SIS API and load into DuckDB."""
    data = sis_api.get_all_attendance()
    df = pd.DataFrame(data)
    row_count = duckdb.write_dataframe(df, "attendance")
    return dg.MaterializeResult(
        metadata={
            "row_count": row_count,
            "columns": list(df.columns),
        }
    )


@dg.asset(
    group_name="extract",
    description="Extract gradebook data from LMS",
    tags=DUCKDB_WRITE_TAG,
    deps=[raw_attendance],  # Serialize DuckDB writes
)
def raw_gradebook(
    lms_api: dg.ResourceParam[LMSApiResource],
    duckdb: dg.ResourceParam[DuckDBResource],
) -> dg.MaterializeResult:
    """Extract gradebook data from the LMS API and load into DuckDB."""
    data = lms_api.get_all_gradebook()
    df = pd.DataFrame(data)
    row_count = duckdb.write_dataframe(df, "gradebook")
    return dg.MaterializeResult(
        metadata={
            "row_count": row_count,
            "columns": list(df.columns),
        }
    )


@dg.asset(
    group_name="extract",
    description="Extract ISAT data from State Reporting",
    tags=DUCKDB_WRITE_TAG,
    deps=[raw_gradebook],  # Serialize DuckDB writes
)
def raw_isat(
    state_api: dg.ResourceParam[StateApiResource],
    duckdb: dg.ResourceParam[DuckDBResource],
) -> dg.MaterializeResult:
    """Extract ISAT data from the State Reporting API and load into DuckDB."""
    data = state_api.get_all_isat()
    df = pd.DataFrame(data)
    row_count = duckdb.write_dataframe(df, "isat")
    return dg.MaterializeResult(
        metadata={
            "row_count": row_count,
            "columns": list(df.columns),
        }
    )
