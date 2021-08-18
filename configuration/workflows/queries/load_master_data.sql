CREATE OR REPLACE EXTERNAL TABLE `${dataset}.master_table`
OPTIONS (
    format = 'CSV',
    uris = ['gs://${data_bucket}/worldcities.csv'],
    skip_leading_rows = 1
)