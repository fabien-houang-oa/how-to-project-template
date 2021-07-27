# Provide the required permission to trigger the config interface

data "google_service_account" "btdpback_configinterface_sa" {
  provider   = google-beta
  project    = local.btdpback_project
  account_id = "btdp-sa-configinterface-${local.project_env}"
}

resource "google_service_account_iam_member" "globalperms" {
  provider = google-beta
  for_each = toset([
    "iam.serviceAccountTokenCreator",
    "iam.serviceAccountUser"
  ])
  service_account_id = data.google_service_account.btdpback_configinterface_sa.name
  role               = "roles/${each.key}"
  member             = "serviceAccount:${data.google_project.default.number}@cloudbuild.gserviceaccount.com"
}
