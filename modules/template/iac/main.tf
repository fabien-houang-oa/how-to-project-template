# main service account of the workload
resource "google_service_account" "default" {
  provider     = google-beta
  account_id   = "btdp-sa-${local.module_name_short}-${local.project_env}"
  display_name = "BTDP configuration API identity"
}

resource "google_cloud_run_service" "default" {
  provider = google-beta
  name     = "btdp-gcr-${local.module_name_short}-${local.region_id}-${local.project_env}"
  location = local.region

  template {
    spec {
      containers {
        image = "gcr.io/${local.project}/${local.module_name}@${local.revision}"
        env {
          name  = "PROJECT_NAME"
          value = local.project
        }
        env {
          name  = "PROJECT_ENV"
          value = local.project_env
        }
        env {
          name  = "APP_NAME"
          value = local.app_name
        }
        env {
          name  = "APP_NAME_SHORT"
          value = local.app_name_short
        }
        env {
          name  = "MODULE_NAME"
          value = local.module_name
        }
        env {
          name  = "MODULE_NAME_SHORT"
          value = local.module_name_short
        }
        env {
          name  = "TIMEOUT"
          value = local.timeout
        }
        env {
          name  = "CONCURRENCY"
          value = local.concurrency
        }
        env {
          name  = "CLOUDRUN_URL_SUFFIX"
          value = local.cloudrun_url_suffix
        }
        resources {
          limits = {
            "cpu"  = "1000m"
            memory = "1Gi"
          }
        }

      }
      service_account_name  = google_service_account.default.email
      container_concurrency = local.concurrency
      timeout_seconds       = 900
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1000"
        #"run.googleapis.com/vpc-access-connector" = data.terraform_remote_state.global.outputs.vpc_serverless_access_btdpsqlaccess
        ##"run.googleapis.com/vpc-access-egress" = "private-ranges-only"
      }
      labels = {
        "env"     = local.project_env
        "project" = "btdp"
        "module"  = local.module_name
      }
    }
  }
  autogenerate_revision_name = true

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# we always ensure a service account on a workload can invoke itself
resource "google_cloud_run_service_iam_member" "sa" {
  provider = google-beta
  location = local.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.default.email}"
}
