locals {
  query_file_extension = "sql"
  query_list = fileset("${local.configuration_folder}/workflows/queries", "*.${local.query_file_extension}")
}

resource "google_storage_bucket" "bucket_queries" {
  name = "${local.app_name_short}-gcs-queries" #TO BE CHANGED if already exist
  project = local.project
}

resource "google_storage_bucket_object" "queries" {
  for_each = local.query_list
  name = each.key
  bucket = google_storage_bucket.bucket_queries.name
  source = "${local.configuration_folder}/workflows/queries/${each.key}"
}