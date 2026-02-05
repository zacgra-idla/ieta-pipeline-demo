-- Unpivot gradebook from wide to long format
-- One row per student per assignment/test

with gradebook as (
    select * from {{ ref('stg_gradebook') }}
),

unpivoted as (
    unpivot gradebook
    on columns(* exclude (student_id, student_name, course_id, section_id, teacher_name, current_grade))
    into
        name assignment_name
        value score
),

parsed as (
    select
        student_id,
        student_name,
        course_id,
        section_id,
        teacher_name,
        current_grade,
        assignment_name,
        score,
        -- Parse assignment type and date from column name
        -- Format: "Assignment 1 (2026-01-09)" or "Test 1 (2026-01-27)"
        case
            when assignment_name like 'Test%' then 'Test'
            else 'Assignment'
        end as assignment_type,
        try_cast(regexp_extract(assignment_name, '\d+') as integer) as assignment_number,
        try_cast(nullif(regexp_extract(assignment_name, '\d{4}-\d{2}-\d{2}'), '') as date) as due_date,
        score is not null as is_submitted
    from unpivoted
)

select * from parsed
