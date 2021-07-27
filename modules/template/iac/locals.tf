# create all the locals variables

locals {
  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  module_name       = var.module_name
  module_name_short = replace(var.module_name, "-", "")

  project     = var.project
  project_env = var.project_env

  cloudrun_url_suffix = var.cloudrun_url_suffix
  revision            = var.revision

  env = jsondecode(file(var.env_file))

  project_roles = toset([])
}

locals {
  zone = lookup(local.env, "zone", "europe-west1-b")

  concurrency = lookup(local.env, "concurrency", 10)
  timeout     = lookup(local.env, "timeout", 900)
}

locals {
  zone_id     = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  region      = lookup(local.env, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id   = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-[a-z]/", "$1$2$3")
  multiregion = lookup(local.env, "multiregion", regex("^europe-", local.zone) == "europe-" ? "eu" : (regex("^us-", local.zone) == "us-" ? "us" : null))
}
