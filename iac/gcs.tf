locals {
  query_file_extension = "sql"
  query_list = {
    for file in fileset("${local.configuration_folder}/workflows/queries", "**/[^.]*.${local.query_file_extension}") :
    file => templatefile(
      "${local.configuration_folder}/workflows/queries/${file}",
      { dataset = "howtoprojecttemplate_ds_c3_101_tutodata_eu_sbx1", #TO BE CHANGED with the dataset created
        data_bucket = google_storage_bucket.bucket_data.name
      } 
    )
  }

  data_list = fileset("../utils/generate_data", "**/[^.]*.csv")
}

resource "google_storage_bucket" "bucket_queries" {
  name = "${local.app_name_short}-gcs-queries-${local.multiregion}-${local.project_env}" 
  project = local.project
}

resource "google_storage_bucket_object" "queries" {
  for_each = local.query_list
  name = each.key
  bucket = google_storage_bucket.bucket_queries.name
  content = each.value
}

resource "google_storage_bucket" "bucket_data" {
  name = "${local.app_name_short}-gcs-tuto-data-${local.multiregion}-${local.project_env}"
  project = local.project
}

resource "google_storage_bucket_object" "data" {
  for_each = local.data_list
  name = each.key
  bucket = google_storage_bucket.bucket_data.name
  source = "../utils/generate_data/${each.key}"
}