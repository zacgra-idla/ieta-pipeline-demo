-- Dimension table for students
-- Combines student info from gradebook and ISAT data

with gradebook_students as (
    select distinct
        student_id,
        student_name
    from {{ ref('stg_gradebook') }}
),

isat_students as (
    select distinct
        eduid,
        student_name
    from {{ ref('stg_isat') }}
),

combined as (
    select
        g.student_id,
        g.student_name,
        i.eduid
    from gradebook_students g
    left join isat_students i on g.student_name = i.student_name
)

select
    row_number() over (order by student_id) as student_key,
    student_id,
    student_name,
    eduid
from combined
