CREATE OR REPLACE EXTERNAL TABLE `${dataset}.master_table`
OPTIONS (
    format = 'CSV',
    uris = ['gs://howtoprojecttemplate-gcs-tuto-data/upload/worldcities.csv'],
    skip_leading_rows = 1
)