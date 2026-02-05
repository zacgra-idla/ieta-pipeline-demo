-- Fact table for ISAT assessments
-- Grain: one row per student

with isat as (
    select * from {{ ref('stg_isat') }}
),

dim_student as (
    select * from {{ ref('dim_student') }}
)

select
    s.student_key,
    -- Math measures
    i.math_scale_score,
    i.math_performance_level,
    -- ELA measures
    i.ela_scale_score,
    i.ela_performance_level
from isat i
left join dim_student s on i.eduid = s.eduid
