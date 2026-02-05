from pathlib import Path

from dagster import Definitions, definitions, load_from_defs_folder

from dagster_demo.resources.sis_api import SISApiResource
from dagster_demo.resources.lms_api import LMSApiResource
from dagster_demo.resources.state_api import StateApiResource


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
            }
        ),
    )
