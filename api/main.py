"""
FastAPI server to serve IETA education data.
"""

from pathlib import Path
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException, Query

app = FastAPI(
    title="IETA Education Data API",
    description="API for student attendance, gradebook, and ISAT data",
    version="1.0.0",
)

DATA_DIR = Path(__file__).parent / "data"


def load_parquet(name: str) -> pd.DataFrame:
    """Load a parquet file from the seeds directory."""
    path = DATA_DIR / f"{name}.parquet"
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Data file {name} not found")
    return pd.read_parquet(path)


@app.get("/")
def root():
    """API health check and available endpoints."""
    return {
        "status": "healthy",
        "endpoints": [
            "/students",
            "/attendance",
            "/gradebook",
            "/isat",
        ],
    }


@app.get("/students")
def get_students(
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    section_id: Optional[str] = Query(None, description="Filter by section ID"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get list of students from ISAT data."""
    df = load_parquet("isat_data")

    if course_id:
        df = df[df["course_id"] == course_id]
    if section_id:
        df = df[df["section_id"] == section_id]

    total = len(df)
    df = df.iloc[offset : offset + limit]

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "data": df.to_dict(orient="records"),
    }


@app.get("/attendance")
def get_attendance(
    student_id: Optional[int] = Query(None, description="Filter by student ID"),
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get attendance records."""
    df = load_parquet("attendance")

    if student_id:
        df = df[df["student_id"] == student_id]
    if course_id:
        df = df[df["course_id"] == course_id]

    total = len(df)
    df = df.iloc[offset : offset + limit]

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "data": df.to_dict(orient="records"),
    }


@app.get("/attendance/{student_id}")
def get_student_attendance(student_id: int):
    """Get attendance for a specific student."""
    df = load_parquet("attendance")
    student_df = df[df["student_id"] == student_id]

    if student_df.empty:
        raise HTTPException(status_code=404, detail=f"Student {student_id} not found")

    return student_df.to_dict(orient="records")[0]


@app.get("/gradebook")
def get_gradebook(
    student_id: Optional[int] = Query(None, description="Filter by student ID"),
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    teacher: Optional[str] = Query(None, description="Filter by teacher"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get gradebook records."""
    df = load_parquet("buzz_gradebook")

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
        "data": df.to_dict(orient="records"),
    }


@app.get("/gradebook/{student_id}")
def get_student_gradebook(student_id: int):
    """Get gradebook for a specific student."""
    df = load_parquet("buzz_gradebook")
    student_df = df[df["student_id"] == student_id]

    if student_df.empty:
        raise HTTPException(status_code=404, detail=f"Student {student_id} not found")

    return student_df.to_dict(orient="records")[0]


@app.get("/isat")
def get_isat(
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    math_level: Optional[str] = Query(None, description="Filter by math performance level"),
    ela_level: Optional[str] = Query(None, description="Filter by ELA performance level"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get ISAT test score records."""
    df = load_parquet("isat_data")

    if course_id:
        df = df[df["course_id"] == course_id]
    if math_level:
        df = df[df["math_performance_level"] == math_level]
    if ela_level:
        df = df[df["ela_performance_level"] == ela_level]

    total = len(df)
    df = df.iloc[offset : offset + limit]

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "data": df.to_dict(orient="records"),
    }


@app.get("/isat/{eduid}")
def get_student_isat(eduid: str):
    """Get ISAT scores for a specific student by EDUID."""
    df = load_parquet("isat_data")
    student_df = df[df["eduid"] == eduid]

    if student_df.empty:
        raise HTTPException(status_code=404, detail=f"Student with EDUID {eduid} not found")

    return student_df.to_dict(orient="records")[0]


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
