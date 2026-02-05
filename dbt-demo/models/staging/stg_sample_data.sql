with source as (
    select * from {{ ref('sample_data') }}
)

select
    id,
    name,
    age,
    city,
    case
        when age < 30 then 'Young'
        when age < 40 then 'Middle'
        else 'Senior'
    end as age_group
from source
