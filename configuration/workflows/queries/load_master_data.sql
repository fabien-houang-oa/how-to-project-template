CREATE OR REPLACE EXTERNAL TABLE howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1.master_table
OPTIONS (
    format = 'CSV',
    uris = ['gs://howtoprojecttemplate-gcs-tuto-data/upload/worldcities.csv'],
    skip_leading_rows = 1
)