
# manages the IAM rules for the CloudBuild service account.
resource "google_project_iam_member" "cicd_cloudbuild_iam" {
  provider = google-beta
  count    = length(local.roles_projects)
  project  = local.roles_projects[count.index].project
  role     = "roles/${local.roles_projects[count.index].role}"
  member   = "serviceAccount:${data.google_project.env_projects[local.roles_projects[count.index].env].number}@cloudbuild.gserviceaccount.com"
}

# inter-project trigger: add permissions to trigger
resource "google_project_iam_member" "inter_project" {
  provider = google-beta
  for_each = { for key, val in local.triggers_env : key => val.next if lookup(val, "next", null) != null }
  project  = lookup(local.triggers_env_conf, each.value, null).project
  role     = "roles/cloudbuild.builds.editor"
  member   = "serviceAccount:${data.google_project.env_projects[each.key].number}@cloudbuild.gserviceaccount.com"
}
