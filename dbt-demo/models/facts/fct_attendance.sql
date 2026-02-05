-- Fact table for attendance
-- Grain: one row per student per school day

with attendance as (
    select * from {{ ref('int_attendance_long') }}
),

dim_student as (
    select * from {{ ref('dim_student') }}
),

dim_course as (
    select * from {{ ref('dim_course') }}
),

dim_section as (
    select * from {{ ref('dim_section') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
)

select
    s.student_key,
    c.course_key,
    sec.section_key,
    d.date_key,
    -- Measures
    a.attendance_status,
    a.is_absent
from attendance a
left join dim_student s on a.student_id = s.student_id
left join dim_course c on a.course_id = c.course_id
left join dim_section sec on a.course_id = sec.course_id and a.section_id = sec.section_id
left join dim_date d on a.school_date = d.full_date
