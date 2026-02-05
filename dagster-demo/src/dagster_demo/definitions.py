from pathlib import Path

from dagster import Definitions, definitions, load_from_defs_folder, multiprocess_executor

from dagster_demo.resources.duckdb import DuckDBResource
from dagster_demo.resources.sis_api import SISApiResource
from dagster_demo.resources.lms_api import LMSApiResource
from dagster_demo.resources.state_api import StateApiResource

# Path to the DuckDB database used by dbt (relative to repo root)
DUCKDB_PATH = Path(__file__).parent.parent.parent.parent / "dbt-demo" / "dev.duckdb"

# Executor with tag-based concurrency limits (OSS alternative to Dagster+ UI)
duckdb_executor = multiprocess_executor.configured({
    "max_concurrent": 4,
    "tag_concurrency_limits": [
        {
            "key": "dagster/concurrency_key",
            "value": "duckdb_write",
            "limit": 1,
        }
    ],
})


@definitions
def defs():
    component_defs = load_from_defs_folder(path_within_project=Path(__file__).parent)
    return Definitions.merge(
        component_defs,
        Definitions(
            resources={
                "sis_api": SISApiResource(),
                "lms_api": LMSApiResource(),
                "state_api": StateApiResource(),
                "duckdb": DuckDBResource(database_path=str(DUCKDB_PATH)),
            },
            executor=duckdb_executor,
        ),
    )
