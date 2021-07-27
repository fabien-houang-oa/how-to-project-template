locals {

  wrk_file_extension = "*.yaml"
  workflows_list = {
    for file in fileset("${local.configuration_folder}/workflows", "**/[^.]*.${local.wrk_file_extension}") :
    replace(basename(file), ".${local.wrk_file_extension}", "") => templatefile(
      "${local.configuration_folder}/workflows/${file}",
      {
        flow_id             = replace(basename(file), ".${local.wrk_file_extension}", ""),
        project             = local.project,
        project_env         = local.project_env,
        location            = local.multiregion,
        cloudrun_url_suffix = local.cloudrun_url_suffix
      }
    )
  }
  library_list = [
    for file in fileset("./${path.module}/library/workflows/", "*.${local.wrk_file_extension}") :
    templatefile(
      "./${path.module}/library/workflows/${file}",
      {
        project             = local.project,
        project_env         = local.project_env,
        location            = local.multiregion,
        cloudrun_url_suffix = local.cloudrun_url_suffix
      }
    )
  ]
  workflows_sa_roles = toset([
    "roles/owner",
    "roles/bigquery.dataOwner",
    "roles/bigquery.admin",
    "roles/storage.admin",
    "roles/pubsub.publisher",
    "roles/run.invoker"
  ])
}
resource "google_service_account" "workflows_sa" {
  project      = local.project
  account_id   = "template-sa-workflow-${local.project_env}"
  display_name = "Service Account for workflow template"
  description  = "Service Account for workflow template"
}

resource "google_workflows_workflow" "workflow" {
  for_each        = local.workflows_list
  name            = trimsuffix(each.key, local.wrk_file_extension)
  project         = local.project
  region          = local.workflow_region
  description     = trimsuffix(each.key, local.wrk_file_extension)
  service_account = google_service_account.workflows_sa.id
  source_contents = join("\n", concat([each.value], local.library_list))
}
