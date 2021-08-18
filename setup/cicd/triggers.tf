# Triggers when creating a Pull Request
resource "google_cloudbuild_trigger" "iac-pullrequest-trigger" {
  provider    = google-beta
  project     = local.pullrequest_project
  name        = "${local.app_name_short}-gcb-pullrequest-${local.pullrequest_env}"
  description = "Plan the main IaC in ${local.pullrequest_env}. Trigger invoked by a pull request in branch ${local.pullrequest_branch}."

  github {
    owner = local.owner
    name  = local.repository_name
    pull_request {
      branch = "^${local.pullrequest_branch}$"
    }
  }

  build {
    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5|md5sum -c -"
      ]
    }

    step {
      id         = "create zip for cloud function"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "zip utils/cloud_functions/run_workflow.zip utils/cloud_functions/main.py utils/cloud_functions/requirements.txt"
      ]
    }

    step {
      id         = "build on ${local.pullrequest_env}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build"
      entrypoint = "bash"
      args = [
        "-c",
        "make APP_NAME=${local.app_name} ENV=${local.pullrequest_env} build"
      ]
    }

    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = ["iac/**"]
}

# Triggers when merging a pull requeset
resource "google_cloudbuild_trigger" "iac-deploy-trigger" {
  for_each    = local.triggers_env
  provider    = google-beta
  project     = lookup(local.triggers_env_conf, each.key, null).project
  name        = "${local.app_name_short}-gcb-deploy-${each.key}"
  description = "Deploy the main IaC in ${each.key}. Trigger invoked by a merge in branch ${each.value.branch}."
  disabled    = lookup(each.value, "disabled", false)

  github {
    owner = local.owner
    name  = local.repository_name
    push {
      branch = "^${each.value.branch}$"
    }
  }

  build {

    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5|md5sum -c -"
      ]
    }

    step {
      id         = "deploy ${each.key}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build"
      entrypoint = "bash"
      args = [
        "-c",
        "make APP_NAME=${local.app_name} ENV=${each.key} build deploy"
      ]
    }
    dynamic "step" {
      for_each = toset(lookup(each.value, "next", "") != "" ? [each.value.next] : [])
      content {
        id   = "goto ${each.value.next}"
        name = "gcr.io/cloud-builders/gcloud"
        args = [
          "--project",
          lookup(local.triggers_env_conf, each.value.next, null).project,
          "beta",
          "builds",
          "triggers",
          "run",
          "${local.app_name_short}-gcb-deploy-${each.value.next}",
          "--branch",
          each.value.branch
        ]
      }
    }


    timeout = "${local.trigger_timeout}s"
  }
  # modification in this directory will invoke the trigger
  included_files = ["iac/**"]
}


# Triggers when creating a Pull Request for a module
resource "google_cloudbuild_trigger" "iac-pullrequest-trigger-module" {
  provider    = google-beta
  for_each    = toset(local.modules)
  project     = local.pullrequest_project
  name        = "${local.app_name_short}-gcb-pullrequest${each.key}-${local.pullrequest_env}"
  description = "Plan the main IaC in ${local.pullrequest_env}. Trigger invoked by a pull request in branch ${local.pullrequest_branch}."

  github {
    owner = local.owner
    name  = local.repository_name
    pull_request {
      branch = "^${local.pullrequest_branch}$"
    }
  }

  build {
    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5|md5sum -c -"
      ]
    }

    step {
      id         = "build on ${local.pullrequest_env}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build"
      entrypoint = "bash"
      args = [
        "-c",
        "make APP_NAME=${local.app_name} ENV=${local.pullrequest_env} build-module-${each.key}"
      ]
    }

    timeout = "${local.trigger_timeout}s"
  }

  # modification in this directory will invoke the trigger
  included_files = ["modules/${each.key}/**"]
}

# Triggers when merging a pull requeset for a module
resource "google_cloudbuild_trigger" "iac-deploy-trigger-module" {
  count       = length(local.modules_triggers_env)
  provider    = google-beta
  project     = lookup(local.triggers_env_conf, local.modules_triggers_env[count.index].env, null).project
  name        = "${local.app_name_short}-gcb-deploy${local.modules_triggers_env[count.index].module}-${local.modules_triggers_env[count.index].env}"
  description = "Deploy the main IaC in ${local.modules_triggers_env[count.index].env}. Trigger invoked by a merge in branch ${local.modules_triggers_env[count.index].branch}."
  disabled    = lookup(local.modules_triggers_env[count.index], "disabled", false)

  github {
    owner = local.owner
    name  = local.repository_name
    push {
      branch = "^${local.modules_triggers_env[count.index].branch}$"
    }
  }

  build {

    step {
      id         = "check files"
      name       = "gcr.io/cloud-builders/gcloud"
      entrypoint = "bash"
      args = [
        "-c",
        "gsutil cat gs://${local.deploy_bucket}/checks/files.md5|md5sum -c -"
      ]
    }

    step {
      id         = "deploy ${local.modules_triggers_env[count.index].env}"
      name       = "gcr.io/itg-btdpshared-gbl-ww-pd/generic-build"
      entrypoint = "bash"
      args = [
        "-c",
        "make APP_NAME=${local.app_name} ENV=${local.modules_triggers_env[count.index].env} build-module-${local.modules_triggers_env[count.index].module} deploy-module-${local.modules_triggers_env[count.index].module}"
      ]
    }
    dynamic "step" {
      for_each = toset(lookup(local.modules_triggers_env[count.index], "next", "") != "" ? [local.modules_triggers_env[count.index].next] : [])
      content {
        id   = "goto ${local.modules_triggers_env[count.index].next}"
        name = "gcr.io/cloud-builders/gcloud"
        args = [
          "--project",
          lookup(local.triggers_env_conf, local.modules_triggers_env[count.index].next, null).project,
          "beta",
          "builds",
          "triggers",
          "run",
          "${local.app_name_short}-gcb-deploy${local.modules_triggers_env[count.index].module}-${local.modules_triggers_env[count.index].next}",
          "--branch",
          local.modules_triggers_env[count.index].branch
        ]
      }
    }


    timeout = "${local.trigger_timeout}s"
  }
  # modification in this directory will invoke the trigger
  included_files = ["modules/${local.modules_triggers_env[count.index].module}/**"]
}
