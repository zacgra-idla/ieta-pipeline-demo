"""
LMS (Learning Management System) API - serves gradebook data.
"""

import json
from pathlib import Path
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException, Query


def df_to_records(df: pd.DataFrame) -> list[dict]:
    """Convert DataFrame to list of dicts, handling NaN values."""
    # to_json handles NaN -> null, then parse back to get Python None
    return json.loads(df.to_json(orient="records"))

app = FastAPI(
    title="LMS API",
    description="Learning Management System API for gradebook data",
    version="1.0.0",
)

DATA_DIR = Path(__file__).parent / "data"


def load_parquet(name: str) -> pd.DataFrame:
    """Load a parquet file from the data directory."""
    path = DATA_DIR / f"{name}.parquet"
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Data file {name} not found")
    return pd.read_parquet(path)


@app.get("/")
def root():
    """API health check."""
    return {
        "status": "healthy",
        "system": "LMS",
        "endpoints": ["/gradebook"],
    }


@app.get("/gradebook")
def get_gradebook(
    student_id: Optional[int] = Query(None, description="Filter by student ID"),
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    teacher: Optional[str] = Query(None, description="Filter by teacher"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get gradebook records."""
    df = load_parquet("gradebook")

    if student_id:
        df = df[df["student_id"] == student_id]
    if course_id:
        df = df[df["course_id"] == course_id]
    if teacher:
        df = df[df["teacher"] == teacher]

    total = len(df)
    df = df.iloc[offset : offset + limit]

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "data": df_to_records(df),
    }


@app.get("/gradebook/{student_id}")
def get_student_gradebook(student_id: int):
    """Get gradebook for a specific student."""
    df = load_parquet("gradebook")
    student_df = df[df["student_id"] == student_id]

    if student_df.empty:
        raise HTTPException(status_code=404, detail=f"Student {student_id} not found")

    return df_to_records(student_df)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
