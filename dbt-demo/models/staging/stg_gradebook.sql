-- Staging model for gradebook data from LMS API
-- Column names are already snake_case from the API

with source as (
    select * from {{ source('raw', 'gradebook') }}
)

select
    student_id,
    student_name,
    course_id,
    section_id,
    teacher as teacher_name,
    current_grade,
    -- Keep all assignment/test columns as-is for unpivoting in intermediate layer
    * exclude (student_id, student_name, course_id, section_id, teacher, current_grade)
from source
