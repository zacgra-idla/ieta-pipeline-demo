"""
Dagster resource for State Reporting API.
"""

from typing import Any

import httpx
from dagster import ConfigurableResource


class StateApiResource(ConfigurableResource):
    """Resource for fetching ISAT data from the State Reporting API."""

    base_url: str = "http://localhost:8003"
    timeout: float = 30.0

    def _get(self, endpoint: str, params: dict[str, Any] | None = None) -> dict:
        """Make a GET request to the API."""
        with httpx.Client(timeout=self.timeout) as client:
            response = client.get(f"{self.base_url}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()

    def get_isat(
        self,
        course_id: str | None = None,
        math_level: str | None = None,
        ela_level: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> dict:
        """Fetch ISAT records from the API."""
        params = {"limit": limit, "offset": offset}
        if course_id:
            params["course_id"] = course_id
        if math_level:
            params["math_level"] = math_level
        if ela_level:
            params["ela_level"] = ela_level
        return self._get("/isat", params)

    def get_all_isat(self) -> list[dict]:
        """Fetch all ISAT records, handling pagination."""
        all_data = []
        offset = 0
        limit = 500

        while True:
            result = self.get_isat(limit=limit, offset=offset)
            all_data.extend(result["data"])
            if len(result["data"]) < limit:
                break
            offset += limit

        return all_data

    def health_check(self) -> bool:
        """Check if the API is healthy."""
        try:
            result = self._get("/")
            return result.get("status") == "healthy"
        except Exception:
            return False
