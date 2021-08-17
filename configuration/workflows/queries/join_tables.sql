CREATE OR REPLACE TABLE `${dataset}.result` AS
WITH master_table AS (
    SELECT * FROM `${dataset}.master_table` 
),
fact_table AS (
    SELECT ARRAY_AGG(id) AS trans_id, ARRAY_AGG(sell) AS trans_sell, ARRAY_AGG(division) AS trans_div, ARRAY_AGG(date) AS trans_date, city_id
    FROM `${dataset}.fact_table`
    GROUP BY city_id
)
SELECT * FROM master_table 
LEFT JOIN fact_table ON master_table.id=fact_table.city_id