
locals {
  roles = [
    "owner",
    "bigquery.dataOwner",
    "storage.admin",
    "iam.serviceAccountUser",
    "iam.serviceAccountTokenCreator"
  ]

  deploy_bucket = var.deploy_bucket

  app_name       = var.app_name
  app_name_short = replace(var.app_name, "-", "")

  env     = jsondecode(file(var.env_file))
  env_dir = dirname(var.env_file)

  project_roles = toset([])

  zone = lookup(local.env, "zone", "europe-west1-b")

  zone_id     = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-([a-z])/", "$1$2$3$4")
  region      = lookup(local.env, "region", replace(local.zone, "/(.*)-[a-z]$/", "$1"))
  region_id   = replace(local.zone, "/([a-z])[a-z]+-([a-z])[a-z]+([0-9])-[a-z]/", "$1$2$3")
  multiregion = lookup(local.env, "multiregion", regex("^europe-", local.zone) == "europe-" ? "eu" : (regex("^us-", local.zone) == "us-" ? "us" : null))

  # specific CI/CD
  organization_name = lookup(local.env, "organization_name", "loreal-datafactory")
  #repository_name   = "${local.organization_name}/${local.app_name}"
  repository_name = local.app_name
  owner           = lookup(local.env, "owner", "loreal-datafactory")
  trigger_timeout = lookup(local.env, "gcb_trigger_timeout", "7200")

  # modules
  modules = split(" ", trimspace(var.modules))

  # CI/CD local conf
  pullrequest_branch = lookup(local.env, "pullrequest_branch", "develop")
  pullrequest_env    = lookup(local.env, "pullrequest_env", "qa")
  triggers_env_default = {
    dv = {
      branch   = "develop"
      disabled = true
    }
    qa = {
      branch = "develop"
      next   = "np"
    }
    np = {
      branch   = "preprod"
      disabled = true
    }
    pd = {
      branch = "master"
    }
  }
  triggers_env = lookup(local.env, "triggers_env", local.triggers_env_default)

  triggers_env_conf   = { for key, val in local.triggers_env : key => jsondecode(file("${local.env_dir}/${key}.json")) }
  pullrequest_project = lookup(local.triggers_env_conf, local.pullrequest_env, null).project

  # roles for each project
  roles_projects = flatten([
    for env, conf in local.triggers_env_conf : [
      for role in local.roles : {
        project = conf.project,
        role    = role
        env     = env
      }
    ]
  ])

  modules_triggers_env = flatten([
    for env, conf in local.triggers_env : [
      for module in local.modules : {
        env      = env
        branch   = conf.branch
        disabled = lookup(conf, "disabled", false)
        next     = lookup(conf, "next", "")
        module   = module
      }
    ]
  ])
}

