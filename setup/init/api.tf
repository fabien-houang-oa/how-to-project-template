resource "google_project_service" "apis" {
  provider           = google-beta
  for_each           = local.apis
  service            = "${each.key}.googleapis.com"
  disable_on_destroy = false
}
