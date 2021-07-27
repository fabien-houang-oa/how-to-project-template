locals {
  apis = toset(split("\n", trimspace(file("../../environments/apis.txt"))))

  project      = var.project
  project_env  = var.project_env
  access_token = var.access_token
  gae_location = var.region == "europe-west1" || var.region == "us-central1" ? replace(var.region, "/1/", "") : var.region

  env = jsondecode(file(var.env_file))

  generic_technical_roles = ["iam.serviceAccountUser", "iam.serviceAccountTokenCreator"]

  btdpback_project = lookup(
    local.env,
    "btdpback_project",
    local.project_env == "dv" || local.project_env == "qa" || local.project_env == "np" || local.project_env == "pd" ? "itg-btdpback-gbl-ww-${local.project_env}" : local.project
  )
  pubsub_technical_roles = ["pubsub.publisher", "pubsub.subscriber"]
}
