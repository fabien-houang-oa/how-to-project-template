CREATE OR REPLACE EXTERNAL TABLE `${dataset}.fact_table`
OPTIONS (
    format = 'CSV',
    uris = ['gs://${data_bucket}/fake_fact_table.csv'],
    skip_leading_rows = 1
)