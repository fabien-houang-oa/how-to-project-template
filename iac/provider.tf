# backend should always be GCS. It's configured from the CLI with:
# terraform init \
#   -backend-config=bucket=$DEPLOY_BUCKET \
#   -backend-config=prefix=terraform-state/global \
#   iac;
terraform {
  backend "gcs" {}
  required_version = "~> 0.14"

  required_providers {
    restapi = {
      source  = "fmontezuma/restapi"
      version = "1.14.1"
    }
  }
}

# google-beta provider is prefered to ensure the last functionalities
# are available
provider "google-beta" {
  project = local.project
  region  = local.region
  zone    = local.zone
}

# load meta data about the project
data "google_project" "default" {
  provider = google-beta
}

# Get the GCR url suffix
data "google_storage_bucket_object_content" "cloudrun_url_suffix" {
  name   = "cloudrun-url-suffix/${local.region}"
  bucket = local.deploy_bucket
}

# OIDC (Open ID Connect) token for BTDP Configuration Interface service
# Required the current user (or service account) to be iam.serviceAccountTokenCreator and iam.serviceAccountUser on BTDP configinterface Service Account
data "google_service_account_id_token" "gcr_configinterface" {
  provider               = google-beta
  target_audience        = "https://btdp-gcr-configinterface-${local.region_id}-${local.project_env}-${local.cloudrun_url_suffix}.a.run.app"
  target_service_account = "btdp-sa-configinterface-${local.project_env}@${local.btdpback_project}.iam.gserviceaccount.com"
}

# REST API provider for Configuration Interface API endpoints
provider "restapi" {
  alias = "gcr_configinterface_api"
  uri   = "https:"
  headers = {
    "Authorization" : "Bearer ${data.google_service_account_id_token.gcr_configinterface.id_token}"
  }
  create_method        = "POST"
  read_method          = "GET"
  update_method        = "PUT"
  destroy_method       = "DELETE"
  write_returns_object = true
}
