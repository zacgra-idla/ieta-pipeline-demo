-- Fact table for grades
-- Grain: one row per student per assignment

with grades as (
    select * from {{ ref('int_grades_long') }}
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

dim_assignment as (
    select * from {{ ref('dim_assignment') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
)

select
    s.student_key,
    c.course_key,
    sec.section_key,
    a.assignment_key,
    d.date_key,
    -- Measures
    g.score,
    g.is_submitted
from grades g
left join dim_student s on g.student_id = s.student_id
left join dim_course c on g.course_id = c.course_id
left join dim_section sec on g.course_id = sec.course_id and g.section_id = sec.section_id
left join dim_assignment a on g.assignment_name = a.assignment_name
left join dim_date d on g.due_date = d.full_date
