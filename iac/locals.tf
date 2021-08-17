# create all the locals variables

locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  configuration_folder = "../configuration"

  project     = var.project
  project_env = var.project_env

  deploy_bucket       = var.deploy_bucket
  cloudrun_url_suffix = trimspace(data.google_storage_bucket_object_content.cloudrun_url_suffix.content)

  env = jsondecode(file(var.env_file))

  project_roles = toset([])

  zone      = lookup(local.env, "zone", "europe-west1-b")
  zone_id   = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  region    = lookup(local.env, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id = replace(local.region, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])/", "$1$2$3")
  multiregion = lookup(
    local.env,
    "multiregion",
    regex("^europe-", local.region) == "europe-" ? "eu" : (regex("^us-", local.region) == "us-" ? "us" : null)
  )

  #workflow curently only available in europe-west4 in europe
  workflow_region = "europe-west4" #lookup(local.env, "workflow_region", local.region)

  btdpback_project = lookup(
    local.env,
    "btdpback_project",
    local.project_env == "dv" || local.project_env == "qa" || local.project_env == "np" || local.project_env == "pd" ? "itg-btdpback-gbl-ww-${local.project_env}" : local.project
  )
  btdpfront_project = lookup(
    local.env,
    "btdpfront_project",
    local.project_env == "dv" || local.project_env == "qa" || local.project_env == "np" || local.project_env == "pd" ? "itg-btdpfront-gbl-ww-${local.project_env}" : local.project
  )
}
