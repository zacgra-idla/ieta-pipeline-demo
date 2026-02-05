"""
Dagster resource for IETA Education Data API.
"""

from typing import Any

import httpx
from dagster import ConfigurableResource


class IETAApiResource(ConfigurableResource):
    """Resource for fetching data from the IETA Education Data API."""

    base_url: str = "http://localhost:8000"
    timeout: float = 30.0

    def _get(self, endpoint: str, params: dict[str, Any] | None = None) -> dict:
        """Make a GET request to the API."""
        with httpx.Client(timeout=self.timeout) as client:
            response = client.get(f"{self.base_url}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()

    def get_students(
        self,
        course_id: str | None = None,
        section_id: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> dict:
        """Fetch students from the API."""
        params = {"limit": limit, "offset": offset}
        if course_id:
            params["course_id"] = course_id
        if section_id:
            params["section_id"] = section_id
        return self._get("/students", params)

    def get_all_students(self) -> list[dict]:
        """Fetch all students, handling pagination."""
        all_data = []
        offset = 0
        limit = 500

        while True:
            result = self.get_students(limit=limit, offset=offset)
            all_data.extend(result["data"])
            if len(result["data"]) < limit:
                break
            offset += limit

        return all_data

    def get_attendance(
        self,
        student_id: int | None = None,
        course_id: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> dict:
        """Fetch attendance records from the API."""
        params = {"limit": limit, "offset": offset}
        if student_id:
            params["student_id"] = student_id
        if course_id:
            params["course_id"] = course_id
        return self._get("/attendance", params)

    def get_all_attendance(self) -> list[dict]:
        """Fetch all attendance records, handling pagination."""
        all_data = []
        offset = 0
        limit = 500

        while True:
            result = self.get_attendance(limit=limit, offset=offset)
            all_data.extend(result["data"])
            if len(result["data"]) < limit:
                break
            offset += limit

        return all_data

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
