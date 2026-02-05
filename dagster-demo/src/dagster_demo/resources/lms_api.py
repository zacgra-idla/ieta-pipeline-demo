"""
Dagster resource for LMS (Learning Management System) API.
"""

from typing import Any

import httpx
from dagster import ConfigurableResource


class LMSApiResource(ConfigurableResource):
    """Resource for fetching gradebook data from the LMS API."""

    base_url: str = "http://localhost:8002"
    timeout: float = 30.0

    def _get(self, endpoint: str, params: dict[str, Any] | None = None) -> dict:
        """Make a GET request to the API."""
        with httpx.Client(timeout=self.timeout) as client:
            response = client.get(f"{self.base_url}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()

    def get_gradebook(
        self,
        student_id: int | None = None,
        course_id: str | None = None,
        teacher: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> dict:
        """Fetch gradebook records from the API."""
        params = {"limit": limit, "offset": offset}
        if student_id:
            params["student_id"] = student_id
        if course_id:
            params["course_id"] = course_id
        if teacher:
            params["teacher"] = teacher
        return self._get("/gradebook", params)

    def get_all_gradebook(self) -> list[dict]:
        """Fetch all gradebook records, handling pagination."""
        all_data = []
        offset = 0
        limit = 500

        while True:
            result = self.get_gradebook(limit=limit, offset=offset)
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
