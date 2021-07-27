locals {
  #process only if we have valid entry group id
  tag = { for k, v in var.tags : k => v if v.entry_group_id != "" }

 #get distinct values for entry group id
  tag_list = distinct( [
    for tag in local.tag : {
      entry_group_id = tag.entry_group_id
    }
    ] )

  tag_output = ({
    for tags in local.tag_list :
    tags.entry_group_id => tags
  })

  region = var.region
}

resource "google_data_catalog_entry_group" "entry_group" {
  for_each       = local.tag_output
  project        = local.project
  region         = local.region
  entry_group_id = each.value.entry_group_id
}

resource "google_data_catalog_entry" "entry_dataset" {
  for_each              = var.datasets
  entry_group           = "projects/${local.project}/locations/${local.region}/entryGroups/${lookup(local.tag, each.value.dataset_id).entry_group_id}"
  entry_id              = each.value.dataset_id
  linked_resource       = "//bigquery.googleapis.com/projects/${local.project}/datasets/${each.value.dataset_id}"
  user_specified_type   = "BIGQUERY_DATASET"
  user_specified_system = "BIGQUERY_DATASET_SYSTEM"
  description           = each.value.description
  depends_on            = [google_bigquery_dataset.datasets]
}

resource "google_data_catalog_entry" "entry_table" {
  for_each              = var.tables
  entry_group           = "projects/${local.project}/locations/${local.region}/entryGroups/${lookup(local.tag, each.value.dataset_id).entry_group_id}"
  entry_id              = join("_", [regex("c[123]{1}", each.value.dataset_id), each.value.table_id])
  linked_resource       = "//bigquery.googleapis.com/projects/${local.project}/datasets/${each.value.dataset_id}/tables/${each.value.table_id}"
  user_specified_type   = "BIGQUERY_TABLE"
  user_specified_system = "BIGQUERY_TABLE_SYSTEM"
  description           = each.value.description
  depends_on            = [google_bigquery_table.tables]
}

resource "google_data_catalog_entry" "entry_matview" {
  for_each              = var.mat_views
  entry_group           = "projects/${local.project}/locations/${local.region}/entryGroups/${lookup(local.tag, each.value.dataset_id).entry_group_id}"
  entry_id              = join("_", [regex("c[123]{1}", each.value.dataset_id), each.value.table_id])
  linked_resource       = "//bigquery.googleapis.com/projects/${local.project}/datasets/${each.value.dataset_id}/matviews/${each.value.table_id}"
  user_specified_type   = "BIGQUERY_TABLE"
  user_specified_system = "BIGQUERY_TABLE_SYSTEM"
  description           = each.value.description
  depends_on            = [google_bigquery_table.tables]
}

resource "google_data_catalog_entry" "entry_view" {
  for_each              = var.views
  entry_group           = "projects/${local.project}/locations/${local.region}/entryGroups/${lookup(local.tag, each.value.dataset_id).entry_group_id}"
  entry_id              = join("_", [regex("c[123]{1}", each.value.dataset_id), each.value.view_id])
  linked_resource       = "//bigquery.googleapis.com/projects/${local.project}/datasets/${each.value.dataset_id}/views/${each.value.view_id}"
  user_specified_type   = "BIGQUERY_TABLE"
  user_specified_system = "BIGQUERY_TABLE_SYSTEM"
  description           = each.value.description
  depends_on            = [google_bigquery_table.views_level_0, google_bigquery_table.views_level_1]
}