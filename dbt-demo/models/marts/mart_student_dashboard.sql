-- Student Dashboard Mart
-- Replicates the Student_Summary view from Instructions
-- One row per student per course with all key metrics

with snapshot as (
    select * from {{ ref('fct_student_snapshot') }}
),

-- Add status emoji based on trend
final as (
    select
        -- Student identification
        student_key,
        student_id,
        student_name,

        -- Course context
        course_key,
        course_id,
        section_key,
        section_id,

        -- Checkpoint grades (Week 3, 6, 9)
        week_3_grade as week_3_grade_check,
        week_6_grade as week_6_grade_check,
        week_9_grade as week_9_grade_check,

        -- Current grade
        current_grade,

        -- Trend status with emoji
        trend_status,
        case trend_status
            when 'Improving' then 'Improving'
            when 'Declining' then 'Declining'
            when 'Failing' then 'Failing'
            when 'Fluctuating' then 'Fluctuating'
            else 'Unknown'
        end as status_label,

        -- Assignment metrics
        total_assignments,
        completed_assignments,
        missing_assignments,
        missing_pct as missing_assignments_pct,

        -- Attendance metrics
        total_school_days,
        days_absent,
        attendance_pct,

        -- Attendance status flag
        case
            when attendance_pct < 0.65 then 'Critical'
            when attendance_pct < 0.75 then 'Warning'
            when attendance_pct < 0.80 then 'Monitor'
            else 'Good'
        end as attendance_status,

        -- ISAT scores
        math_scale_score as isat_math_score,
        math_performance_level as isat_math_level,
        ela_scale_score as isat_ela_score,
        ela_performance_level as isat_ela_level,

        -- Risk indicators (from Instructions conditional formatting rules)
        case
            when current_grade < 60 then 'High'
            when current_grade < 65 then 'Medium'
            when current_grade < 70 then 'Low'
            else 'None'
        end as grade_risk,

        case
            when missing_pct >= 20 then 'High'
            when missing_pct >= 15 then 'Medium'
            else 'Low'
        end as missing_work_risk,

        -- Overall risk score (composite)
        case
            when trend_status = 'Failing' then 'Critical'
            when current_grade < 60 or attendance_pct < 0.65 then 'High'
            when current_grade < 70 or attendance_pct < 0.75 or missing_pct >= 20 then 'Medium'
            when trend_status = 'Declining' then 'Monitor'
            else 'On Track'
        end as overall_risk_level

    from snapshot
)

select * from final
order by
    overall_risk_level desc,  -- Critical/High risk first
    current_grade asc,
    student_name
