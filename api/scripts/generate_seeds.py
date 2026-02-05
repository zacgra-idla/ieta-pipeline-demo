#!/usr/bin/env python3
"""
Generate larger synthetic seed data for IETA demo.
"""

import random
from datetime import date, timedelta
from pathlib import Path

import pandas as pd

# Configuration
NUM_STUDENTS = 500
SEEDS_DIR = Path(__file__).parent.parent / "data"

# Date ranges
ATTENDANCE_START = date(2026, 1, 5)
ATTENDANCE_END = date(2026, 3, 6)
ASSIGNMENT_DATES = [date(2026, 1, 9) + timedelta(days=i * 2) for i in range(40)]
TEST_DATES = [date(2026, 1, 27), date(2026, 2, 16), date(2026, 3, 8), date(2026, 3, 28)]

# Student name pools
FIRST_NAMES = [
    "Emma", "Liam", "Olivia", "Noah", "Ava", "Ethan", "Sophia", "Mason",
    "Isabella", "William", "Mia", "James", "Charlotte", "Benjamin", "Amelia",
    "Lucas", "Harper", "Henry", "Evelyn", "Alexander", "Abigail", "Michael",
    "Emily", "Daniel", "Elizabeth", "Jacob", "Sofia", "Logan", "Avery", "Jackson",
    "Ella", "Sebastian", "Scarlett", "Mateo", "Grace", "Jack", "Chloe", "Owen",
    "Victoria", "Theodore", "Riley", "Aiden", "Aria", "Samuel", "Lily", "Ryan",
    "Aurora", "John", "Zoey", "Luke", "Penelope", "Gabriel", "Layla", "Anthony",
    "Nora", "Dylan", "Camila", "Leo", "Hannah", "Lincoln", "Addison", "Jaxon",
    "Eleanor", "Asher", "Stella", "Christopher", "Bella", "Josiah", "Lucy",
    "Andrew", "Paisley", "Thomas", "Natalie", "David", "Skylar", "Joseph"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
    "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Chen", "Kim", "Patel", "Singh", "Kumar", "Shah"
]

COURSES = ["BUZZ-MATH-7", "BUZZ-MATH-8", "BUZZ-ELA-7", "BUZZ-ELA-8", "BUZZ-SCI-7"]
SECTIONS = ["SEC-01", "SEC-02", "SEC-03"]
TEACHERS = ["Mr. Anderson", "Ms. Baker", "Mr. Chen", "Ms. Davis", "Mr. Edwards"]

PERFORMANCE_LEVELS = ["Below Basic", "Basic", "Proficient", "Advanced"]


def get_weekdays(start: date, end: date) -> list[date]:
    """Get all weekdays between start and end dates."""
    days = []
    current = start
    while current <= end:
        if current.weekday() < 5:  # Monday = 0, Friday = 4
            days.append(current)
        current += timedelta(days=1)
    return days


def generate_student_name(used_names: set) -> str:
    """Generate a unique student name."""
    while True:
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        if name not in used_names:
            used_names.add(name)
            return name


def generate_attendance_status(absence_rate: float) -> str:
    """Generate attendance status based on absence rate."""
    return "Absent" if random.random() < absence_rate else ""


def generate_grade(base: int, variance: int = 15) -> int | None:
    """Generate a grade with some variance, occasionally missing."""
    if random.random() < 0.05:  # 5% chance of missing grade
        return None
    grade = base + random.randint(-variance, variance)
    return max(0, min(100, grade))


def generate_isat_score(performance_level: str) -> int:
    """Generate ISAT score based on performance level."""
    ranges = {
        "Below Basic": (600, 659),
        "Basic": (660, 719),
        "Proficient": (720, 769),
        "Advanced": (770, 800),
    }
    low, high = ranges[performance_level]
    return random.randint(low, high)


def generate_students() -> list[dict]:
    """Generate student data."""
    students = []
    used_names = set()

    for i in range(NUM_STUDENTS):
        student_id = 1001 + i
        name = generate_student_name(used_names)
        course = random.choice(COURSES)
        section = random.choice(SECTIONS)
        teacher = random.choice(TEACHERS)

        # Student characteristics that influence their data
        base_grade = random.randint(50, 95)
        absence_rate = random.uniform(0.05, 0.25)

        # ISAT performance correlates somewhat with grades
        if base_grade >= 85:
            math_level = random.choices(PERFORMANCE_LEVELS, weights=[5, 15, 30, 50])[0]
            ela_level = random.choices(PERFORMANCE_LEVELS, weights=[10, 20, 35, 35])[0]
        elif base_grade >= 70:
            math_level = random.choices(PERFORMANCE_LEVELS, weights=[15, 30, 35, 20])[0]
            ela_level = random.choices(PERFORMANCE_LEVELS, weights=[15, 30, 35, 20])[0]
        elif base_grade >= 55:
            math_level = random.choices(PERFORMANCE_LEVELS, weights=[25, 40, 25, 10])[0]
            ela_level = random.choices(PERFORMANCE_LEVELS, weights=[25, 40, 25, 10])[0]
        else:
            math_level = random.choices(PERFORMANCE_LEVELS, weights=[40, 35, 20, 5])[0]
            ela_level = random.choices(PERFORMANCE_LEVELS, weights=[40, 35, 20, 5])[0]

        students.append({
            "student_id": student_id,
            "name": name,
            "course": course,
            "section": section,
            "teacher": teacher,
            "base_grade": base_grade,
            "absence_rate": absence_rate,
            "math_level": math_level,
            "ela_level": ela_level,
            "eduid": f"{random.randint(100, 999)}FAKE{random.randint(10, 99)}",
        })

    return students


def write_attendance(students: list[dict]):
    """Write attendance seed file."""
    weekdays = get_weekdays(ATTENDANCE_START, ATTENDANCE_END)
    date_cols = [d.strftime("%Y-%m-%d") for d in weekdays]

    rows = []
    for student in students:
        row = {
            "student_id": student["student_id"],
            "student_name": student["name"],
            "course_id": student["course"],
            "section_id": student["section"],
        }
        for d in weekdays:
            row[d.strftime("%Y-%m-%d")] = generate_attendance_status(student["absence_rate"])
        rows.append(row)

    df = pd.DataFrame(rows)
    df.to_parquet(SEEDS_DIR / "attendance.parquet", index=False)
    print(f"Written {len(students)} rows to attendance.parquet")


def write_gradebook(students: list[dict]):
    """Write gradebook seed file."""
    assignment_cols = [f"assignment_{i+1}" for i in range(len(ASSIGNMENT_DATES))]
    test_cols = [f"test_{i+1}" for i in range(len(TEST_DATES))]

    rows = []
    for student in students:
        row = {
            "student_id": student["student_id"],
            "student_name": student["name"],
            "course_id": student["course"],
            "section_id": student["section"],
            "teacher": student["teacher"],
        }

        grades = []
        for col in assignment_cols:
            grade = generate_grade(student["base_grade"], variance=12)
            row[col] = grade
            if grade is not None:
                grades.append(grade)

        for col in test_cols:
            grade = generate_grade(student["base_grade"], variance=10)
            row[col] = grade
            if grade is not None:
                grades.append(grade)

        row["current_grade"] = round(sum(grades) / len(grades), 1) if grades else None
        rows.append(row)

    df = pd.DataFrame(rows)
    df.to_parquet(SEEDS_DIR / "buzz_gradebook.parquet", index=False)
    print(f"Written {len(students)} rows to buzz_gradebook.parquet")


def write_isat(students: list[dict]):
    """Write ISAT seed file."""
    rows = []
    for student in students:
        row = {
            "eduid": student["eduid"],
            "student_name": student["name"],
            "course_id": student["course"],
            "section_id": student["section"],
            "math_scale_score": generate_isat_score(student["math_level"]),
            "math_performance_level": student["math_level"],
            "ela_scale_score": generate_isat_score(student["ela_level"]),
            "ela_performance_level": student["ela_level"],
        }
        rows.append(row)

    df = pd.DataFrame(rows)
    df.to_parquet(SEEDS_DIR / "isat_data.parquet", index=False)
    print(f"Written {len(students)} rows to isat_data.parquet")


def main():
    print(f"Generating data for {NUM_STUDENTS} students...")

    # Create scripts directory if needed
    SEEDS_DIR.mkdir(exist_ok=True)

    students = generate_students()
    write_attendance(students)
    write_gradebook(students)
    write_isat(students)

    print("Done!")


if __name__ == "__main__":
    main()
