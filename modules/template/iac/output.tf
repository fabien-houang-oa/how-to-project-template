output "app_name" {
  value = local.app_name
}

output "app_name_short" {
  value = local.app_name_short
}

output "module_name" {
  value = local.module_name
}

output "module_name_short" {
  value = local.module_name_short
}

output "zone" {
  value = local.zone
}

output "zone_id" {
  value = local.zone_id
}

output "region" {
  value = local.region
}

output "region_id" {
  value = local.region_id
}

output "multiregion" {
  value = local.multiregion
}

output "cloudrun_url_suffix" {
  value = local.cloudrun_url_suffix
}

output "module_identity" {
  value = google_service_account.default.email
}

output "deployed_service" {
  value = google_cloud_run_service.default.name
}

output "deployed_revision" {
  value = "gcr.io/${local.project}/${local.module_name}@${local.revision}"
}

output "deployed_url" {
  value = google_cloud_run_service.default.status[0].url
}
