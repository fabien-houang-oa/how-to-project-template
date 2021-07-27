locals {
  tech_lead_group = "gcp-btdp-fr-gbl-lead@loreal.com"
  itg_security_sa = "system@itg-btdpsecurity-gbl-ww-pd.iam.gserviceaccount.com"
  developer_group = "gcp-btdp-fr-gbl-dv@loreal.com"

  default_owners_by_env = {
    "dv" = ["group:${local.tech_lead_group}", "serviceAccount:${local.itg_security_sa}", "group:${local.developer_group}"],
    "qa" = ["group:${local.tech_lead_group}", "serviceAccount:${local.itg_security_sa}", "group:${local.developer_group}"],
    "np" = ["serviceAccount:${local.itg_security_sa}"],
    "pd" = ["serviceAccount:${local.itg_security_sa}"],
  }
  default_owners  = concat(["projectOwners"], lookup(local.default_owners_by_env, var.project_env, []))
  default_editors = ["projectWriters"]
  default_viewers = ["projectReaders"]
}

resource "google_bigquery_dataset" "datasets" {
  for_each      = var.datasets
  project       = each.value.project
  dataset_id    = each.value.dataset_id
  friendly_name = each.value.friendly_name
  description   = each.value.description
  location      = upper(each.value.location)

  delete_contents_on_destroy = each.value.delete_contents_on_destroy
  labels = {
    env = var.project_env
  }
  default_table_expiration_ms = each.value.default_table_expiration_ms
}

resource "google_bigquery_dataset_iam_binding" "owners" {
  for_each   = var.permissions
  project    = each.value.project
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataOwner"
  members    = concat(local.default_owners, contains(["dv", "qa", "np", "pd"], var.project_env) ? each.value.dataset_permissions[var.project_env]["owners"] : [])
  depends_on = [google_bigquery_dataset.datasets]
}

resource "google_bigquery_dataset_iam_binding" "editors" {
  for_each   = var.permissions
  project    = each.value.project
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataEditor"
  members    = concat(local.default_editors, contains(["dv", "qa", "np", "pd"], var.project_env) ? each.value.dataset_permissions[var.project_env]["editors"] : [])
  depends_on = [google_bigquery_dataset.datasets]
}

resource "google_bigquery_dataset_iam_binding" "viewers" {
  for_each   = var.permissions
  project    = each.value.project
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataViewer"
  members    = concat(local.default_viewers, contains(["dv", "qa", "np", "pd"], var.project_env) ? each.value.dataset_permissions[var.project_env]["viewers"] : [])
  depends_on = [google_bigquery_dataset.datasets]
}