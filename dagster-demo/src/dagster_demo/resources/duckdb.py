"""DuckDB resource for managing database connections."""

from contextlib import contextmanager
from pathlib import Path
from typing import Generator

import duckdb
import pandas as pd

from dagster import ConfigurableResource


class DuckDBResource(ConfigurableResource):
    """Resource for interacting with DuckDB.

    Provides methods for reading and writing data with proper connection management.
    Use the dagster/concurrency_key tag on assets to serialize writes.
    """

    database_path: str

    @contextmanager
    def get_connection(self) -> Generator[duckdb.DuckDBPyConnection, None, None]:
        """Get a DuckDB connection context manager."""
        conn = duckdb.connect(self.database_path)
        try:
            yield conn
        finally:
            conn.close()

    def write_dataframe(
        self,
        df: pd.DataFrame,
        table_name: str,
        schema: str = "raw",
        replace: bool = True
    ) -> int:
        """Write a DataFrame to DuckDB.

        Args:
            df: DataFrame to write
            table_name: Target table name
            schema: Target schema (default: raw)
            replace: If True, drop existing table first

        Returns:
            Number of rows written
        """
        with self.get_connection() as conn:
            conn.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
            if replace:
                conn.execute(f"DROP TABLE IF EXISTS {schema}.{table_name}")
            conn.execute(f"CREATE TABLE {schema}.{table_name} AS SELECT * FROM df")
            return len(df)

    def read_table(self, table_name: str, schema: str = "raw") -> pd.DataFrame:
        """Read a table from DuckDB as a DataFrame."""
        with self.get_connection() as conn:
            return conn.execute(f"SELECT * FROM {schema}.{table_name}").fetchdf()

    def execute(self, query: str) -> None:
        """Execute a query against DuckDB."""
        with self.get_connection() as conn:
            conn.execute(query)
