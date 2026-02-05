-- Staging model for attendance data from SIS API
-- Column names are already snake_case from the API

with source as (
    select * from {{ source('raw', 'attendance') }}
)

select
    student_id,
    student_name,
    course_id,
    section_id,
    -- Keep all date columns as-is for unpivoting in intermediate layer
    * exclude (student_id, student_name, course_id, section_id)
from source
