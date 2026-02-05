-- Dimension table for courses

with courses as (
    select distinct
        course_id
    from {{ ref('stg_gradebook') }}
),

parsed as (
    select
        course_id,
        -- Parse subject and grade level from course_id (e.g., "BUZZ-MATH-7")
        split_part(course_id, '-', 2) as subject,
        cast(split_part(course_id, '-', 3) as integer) as grade_level
    from courses
)

select
    row_number() over (order by course_id) as course_key,
    course_id,
    subject,
    grade_level
from parsed
