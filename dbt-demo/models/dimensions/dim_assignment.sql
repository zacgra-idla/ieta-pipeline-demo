-- Dimension table for assignments and tests

with assignments as (
    select distinct
        assignment_name,
        assignment_type,
        assignment_number,
        due_date
    from {{ ref('int_grades_long') }}
    where assignment_name is not null
)

select
    row_number() over (order by due_date, assignment_type, assignment_number) as assignment_key,
    assignment_name,
    assignment_type,
    assignment_number,
    due_date
from assignments
