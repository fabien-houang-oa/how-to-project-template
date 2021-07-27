terraform {
  required_version = "~> 0.14"
  backend "gcs" {}
}

provider "google-beta" {
  project = local.project
}

data "google_project" "default" {
  provider = google-beta
}
