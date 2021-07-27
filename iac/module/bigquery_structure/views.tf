/*We have defined view level dependency in this code. "level" information is
provided in views configuration file and it is mandatory. If there is no
dependency on another view then the level is provided as '0'. If any dependency
on another view then the level is provided as '1'. Currently this file can handle
only dependecies until level '1', if there are more dependencies to be checked this
file has to be modified to handle additional blocks.
views_level_0 will handle only for level = 0 as defined in views config file
views_level_1 will handle only for level = 1 as defined in views config file.
*/

locals {
  views_level_0 = { for k, v in var.views : k => v if v.level == 0 }
  views_level_1 = { for k, v in var.views : k => v if v.level == 1 }
}

resource "google_bigquery_table" "materialized_views" {

  for_each = var.mat_views

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.table_id
  description         = each.value.description
  deletion_protection = false

  materialized_view {
    query               = each.value.query
    enable_refresh      = each.value.enable_refresh
    refresh_interval_ms = each.value.refresh_interval_ms
  }
  depends_on = [google_bigquery_table.tables]

}

resource "google_bigquery_table" "views_level_0" {

  for_each = local.views_level_0

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.tables]

}

resource "google_bigquery_table" "views_level_1" {

  for_each = local.views_level_1

  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.view_id
  description         = each.value.description
  deletion_protection = false

  view {
    query          = each.value.query
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.views_level_0]

}