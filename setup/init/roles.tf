# IAM rules for the compute service account.
resource "google_project_iam_member" "compute_permissions" {
  provider   = google-beta
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:${data.google_project.default.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for cloud pubsub service account
resource "google_project_iam_member" "generic_permissions" {
  provider   = google-beta
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:service-${data.google_project.default.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for cloud pubsub service account specific
resource "google_project_iam_member" "pubsub_permissions" {
  provider   = google-beta
  for_each   = toset(local.pubsub_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:service-${data.google_project.default.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for cloud tasks service account
resource "google_project_iam_member" "cloudtasks_permissions" {
  provider   = google-beta
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:service-${data.google_project.default.number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}

# IAM rules for cloud scheduler service account
resource "google_project_iam_member" "cloudscheduler_permissions" {
  provider   = google-beta
  for_each   = toset(local.generic_technical_roles)
  role       = "roles/${each.key}"
  member     = "serviceAccount:service-${data.google_project.default.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
  depends_on = [google_project_service.apis]
}
