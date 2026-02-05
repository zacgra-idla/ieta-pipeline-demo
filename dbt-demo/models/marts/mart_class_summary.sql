-- Class Summary Mart
-- Replicates the Pivot Table view from Instructions
-- Aggregates: Total Students, Lowest Grade, Highest Grade, Class Average per Course

with student_grades as (
    select
        course_id,
        section_id,
        student_id,
        current_grade
    from {{ ref('fct_student_snapshot') }}
    where current_grade is not null
)

select
    course_id,
    section_id,
    count(distinct student_id) as total_students,
    min(current_grade) as lowest_grade,
    max(current_grade) as highest_grade,
    round(avg(current_grade), 1) as class_average,
    -- Grade distribution
    sum(case when current_grade >= 90 then 1 else 0 end) as count_a,
    sum(case when current_grade >= 80 and current_grade < 90 then 1 else 0 end) as count_b,
    sum(case when current_grade >= 70 and current_grade < 80 then 1 else 0 end) as count_c,
    sum(case when current_grade >= 60 and current_grade < 70 then 1 else 0 end) as count_d,
    sum(case when current_grade < 60 then 1 else 0 end) as count_f
from student_grades
group by course_id, section_id
order by course_id, section_id
