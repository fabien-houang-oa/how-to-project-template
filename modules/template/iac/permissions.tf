resource "google_project_iam_member" "logging" {
  for_each = local.project_roles
  provider = google-beta
  role     = each.key
  member   = "serviceAccount:${google_service_account.default.email}"
}
