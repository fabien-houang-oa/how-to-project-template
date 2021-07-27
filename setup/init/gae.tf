resource "google_app_engine_application" "app" {
  provider      = google-beta
  location_id   = local.gae_location
  database_type = "CLOUD_FIRESTORE"
  depends_on    = [google_project_service.apis]
}
