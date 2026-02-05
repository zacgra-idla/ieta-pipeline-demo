from pathlib import Path

from dagster import Definitions, definitions, load_from_defs_folder

from dagster_demo.resources.ieta_api import IETAApiResource


@definitions
def defs():
    component_defs = load_from_defs_folder(path_within_project=Path(__file__).parent)
    return Definitions.merge(
        component_defs,
        Definitions(
            resources={
                "ieta_api": IETAApiResource(),
            }
        ),
    )
