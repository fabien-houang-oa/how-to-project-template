terraform {
  required_version = "~> 0.14"
  backend "gcs" {}
}

provider "google-beta" {
}
