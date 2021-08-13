CREATE OR REPLACE TABLE `howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1.result` AS
WITH master_table AS (
    SELECT * FROM `howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1.master_table` 
),
fact_table AS (
    SELECT ARRAY_AGG(id) AS trans_id, ARRAY_AGG(sell) AS trans_sell, ARRAY_AGG(division) AS trans_div, ARRAY_AGG(date) AS trans_date, city_id
    FROM `howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1.fact_table`
    GROUP BY city_id
)
SELECT * FROM master_table 
LEFT JOIN fact_table ON master_table.id=fact_table.city_id