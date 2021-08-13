CREATE OR REPLACE EXTERNAL TABLE howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1.fact_table
OPTIONS (
    format = 'CSV',
    uris = ['gs://howtoprojecttemplate-gcs-tuto-data/fake_fact_table.csv'],
    skip_leading_rows = 1
)