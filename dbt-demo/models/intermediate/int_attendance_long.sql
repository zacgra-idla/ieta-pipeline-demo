-- Unpivot attendance from wide to long format
-- One row per student per school day

with attendance as (
    select * from {{ ref('stg_attendance') }}
),

unpivoted as (
    unpivot attendance
    on columns(* exclude (student_id, student_name, course_id, section_id))
    into
        name date_column
        value attendance_status
),

parsed as (
    select
        student_id,
        student_name,
        course_id,
        section_id,
        -- The column name IS the date (e.g., "2026-01-05")
        cast(date_column as date) as school_date,
        coalesce(attendance_status, 'Present') as attendance_status,
        attendance_status = 'Absent' as is_absent
    from unpivoted
)

select * from parsed
