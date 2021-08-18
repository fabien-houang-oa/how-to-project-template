locals {
  query_file_extension = "sql"
  query_list = {
    for file in fileset("${local.configuration_folder}/workflows/queries", "**/[^.]*.${local.query_file_extension}") :
    file => templatefile(
      "${local.configuration_folder}/workflows/queries/${file}",
      { dataset = "howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1" } #TO BE CHANGED with the created dataset
    )
  }
}

resource "google_storage_bucket" "bucket_queries" {
  name = "${local.app_name_short}-gcs-queries-${local.multiregion}-${local.project_env}" #TO BE CHANGED if already exist
  project = local.project
}

resource "google_storage_bucket_object" "queries" {
  for_each = local.query_list
  name = each.key
  bucket = google_storage_bucket.bucket_queries.name
  content = each.value
}