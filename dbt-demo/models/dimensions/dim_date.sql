-- Dimension table for dates
-- Covers the school term with checkpoint weeks marked

with date_spine as (
    select unnest(generate_series(
        date '2026-01-05',
        date '2026-03-28',
        interval '1 day'
    ))::date as full_date
),

enriched as (
    select
        full_date,
        extract(week from full_date) as week_number,
        extract(month from full_date) as month_number,
        strftime(full_date, '%B') as month_name,  -- DuckDB uses strftime, not to_char
        extract(quarter from full_date) as quarter,
        extract(dow from full_date) as day_of_week,
        -- Checkpoint weeks based on Instructions file
        case
            when full_date = date '2026-01-23' then 'Week 3'
            when full_date = date '2026-02-13' then 'Week 6'
            when full_date = date '2026-03-06' then 'Week 9'
            else null
        end as checkpoint_name,
        full_date in (date '2026-01-23', date '2026-02-13', date '2026-03-06') as is_checkpoint_date,
        -- Is it a school day? (Mon-Fri)
        extract(dow from full_date) between 1 and 5 as is_school_day
    from date_spine
)

select
    row_number() over (order by full_date) as date_key,
    full_date,
    week_number,
    month_number,
    month_name,
    quarter,
    day_of_week,
    checkpoint_name,
    is_checkpoint_date,
    is_school_day
from enriched
