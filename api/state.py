"""
State Reporting API - serves ISAT assessment data.
"""

from pathlib import Path
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException, Query

app = FastAPI(
    title="State Reporting API",
    description="State reporting API for ISAT assessment data",
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
        "system": "State Reporting",
        "endpoints": ["/isat"],
    }


@app.get("/isat")
def get_isat(
    course_id: Optional[str] = Query(None, description="Filter by course ID"),
    math_level: Optional[str] = Query(None, description="Filter by math performance level"),
    ela_level: Optional[str] = Query(None, description="Filter by ELA performance level"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """Get ISAT assessment records."""
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

    return student_df.to_dict(orient="records")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8003)
