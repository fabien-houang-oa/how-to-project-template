resource "google_storage_bucket" "bucket" {
  name = "${local.app_name_short}-gcs-functions"
  project = local.project
}

resource "google_storage_bucket_object" "archive" {
  name   = "run_workflow.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.module}/../utils/cloud_functions/run_workflow.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "run_workflow"
  description = "Run my workflow"
  runtime     = "python38"
  project     = local.project
  region      = local.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  timeout               = 60
  entry_point           = "hello_gcs"
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource = "howtoprojecttemplate-gcs-tuto-data"
  }
}

# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "user:fabien.houang@loreal.com"
}