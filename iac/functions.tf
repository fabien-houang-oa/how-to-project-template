resource "google_storage_bucket" "bucket_function" {
  name = "${local.app_name_short}-gcs-functions" #TO BE CHANGED if already exist
  project = local.project
  force_destroy = true
}

resource "google_storage_bucket_object" "archive" {
  name   = "run_workflow.zip"
  bucket = google_storage_bucket.bucket_function.name
  source = "../utils/cloud_functions/run_workflow.zip" #path to the zip of the code to be executed on Cloud Function
}

resource "google_cloudfunctions_function" "function" {
  name        = "run_workflow"
  description = "Run my workflow"
  runtime     = "python38"
  project     = local.project
  region      = local.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket_function.name
  source_archive_object = google_storage_bucket_object.archive.name
  timeout               = 60
  entry_point           = "hello_gcs"
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource = "${local.app_name_short}-gcs-tuto-data" #TO BE REPLACED
  }
}

# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "user:fabien.houang@loreal.com" #TO BE REPLACED 
}