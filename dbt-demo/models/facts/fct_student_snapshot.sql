-- Student snapshot fact table
-- Implements the Student_Summary transformations from the Instructions
-- Grain: one row per student per course

with grades as (
    select * from {{ ref('int_grades_long') }}
),

attendance as (
    select * from {{ ref('int_attendance_long') }}
),

isat as (
    select * from {{ ref('stg_isat') }}
),

dim_student as (
    select * from {{ ref('dim_student') }}
),

dim_course as (
    select * from {{ ref('dim_course') }}
),

dim_section as (
    select * from {{ ref('dim_section') }}
),

-- Checkpoint dates from Instructions
checkpoints as (
    select
        date '2026-01-23' as week_3_date,
        date '2026-02-13' as week_6_date,
        date '2026-03-06' as week_9_date
),

-- Grade metrics by student/course
grade_metrics as (
    select
        student_id,
        course_id,
        section_id,
        -- Total and completed assignments
        count(*) as total_assignments,
        count(score) as completed_assignments,
        count(*) - count(score) as missing_assignments,
        round((count(*) - count(score))::numeric / count(*) * 100, 1) as missing_pct,
        -- Current grade
        max(current_grade) as current_grade,
        -- Checkpoint grades (cumulative averages)
        avg(case when due_date <= (select week_3_date from checkpoints) then score end) as week_3_grade,
        avg(case when due_date <= (select week_6_date from checkpoints) then score end) as week_6_grade,
        avg(case when due_date <= (select week_9_date from checkpoints) then score end) as week_9_grade
    from grades
    group by student_id, course_id, section_id
),

-- Attendance metrics by student/course
attendance_metrics as (
    select
        student_id,
        course_id,
        section_id,
        count(*) as total_school_days,
        sum(case when is_absent then 1 else 0 end) as days_absent,
        round(1.0 - (sum(case when is_absent then 1 else 0 end)::numeric / count(*)), 3) as attendance_pct
    from attendance
    group by student_id, course_id, section_id
),

-- Combine all metrics
combined as (
    select
        g.student_id,
        g.course_id,
        g.section_id,
        -- Grade metrics
        g.current_grade,
        g.total_assignments,
        g.completed_assignments,
        g.missing_assignments,
        g.missing_pct,
        -- Checkpoint grades
        round(g.week_3_grade, 1) as week_3_grade,
        round(g.week_6_grade, 1) as week_6_grade,
        round(g.week_9_grade, 1) as week_9_grade,
        -- Trend status (from Instructions)
        case
            when g.week_9_grade < 60 then 'Failing'
            when g.week_3_grade < g.week_6_grade and g.week_6_grade < g.week_9_grade then 'Improving'
            when g.week_3_grade > g.week_6_grade and g.week_6_grade > g.week_9_grade then 'Declining'
            else 'Fluctuating'
        end as trend_status,
        -- Attendance metrics
        a.total_school_days,
        a.days_absent,
        a.attendance_pct
    from grade_metrics g
    left join attendance_metrics a
        on g.student_id = a.student_id
        and g.course_id = a.course_id
        and g.section_id = a.section_id
),

-- Join with dimensions and ISAT
final as (
    select
        s.student_key,
        c.course_key,
        sec.section_key,
        -- Student info
        s.student_id,
        s.student_name,
        -- Course info
        cm.course_id,
        cm.section_id,
        -- Grade metrics
        cm.current_grade,
        cm.total_assignments,
        cm.completed_assignments,
        cm.missing_assignments,
        cm.missing_pct,
        -- Checkpoint grades
        cm.week_3_grade,
        cm.week_6_grade,
        cm.week_9_grade,
        cm.trend_status,
        -- Attendance metrics
        cm.total_school_days,
        cm.days_absent,
        cm.attendance_pct,
        -- ISAT scores
        i.math_scale_score,
        i.math_performance_level,
        i.ela_scale_score,
        i.ela_performance_level
    from combined cm
    left join dim_student s on cm.student_id = s.student_id
    left join dim_course c on cm.course_id = c.course_id
    left join dim_section sec on cm.course_id = sec.course_id and cm.section_id = sec.section_id
    left join isat i on s.student_name = i.student_name
)

select * from final
