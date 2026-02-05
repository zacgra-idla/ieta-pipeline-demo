-- Dimension table for sections (includes teacher)

with sections as (
    select distinct
        course_id,
        section_id,
        teacher_name
    from {{ ref('stg_gradebook') }}
)

select
    row_number() over (order by course_id, section_id) as section_key,
    course_id,
    section_id,
    teacher_name
from sections
