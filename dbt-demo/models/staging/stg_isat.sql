-- Staging model for ISAT assessment data from State Reporting API
-- Column names are already snake_case from the API

with source as (
    select * from {{ source('raw', 'isat') }}
)

select
    eduid,
    student_name,
    course_id,
    section_id,
    math_scale_score,
    math_performance_level,
    ela_scale_score,
    ela_performance_level
from source
