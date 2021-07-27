/*Tables will be created only if previous table version config yaml files are
available. Value for field previous_version = '0', if the table is initial
version and if previous version exist then previous_version ='tablename_v1'.
Removing config file for table's older version will make the flag value of previous_version
as false. */

locals {
  table = { for k, v in var.tables : k => v if v.previous_version == true }
}

resource "google_bigquery_table" "tables" {
  for_each            = local.table
  project             = each.value.project
  dataset_id          = each.value.dataset_id
  table_id            = each.value.table_id
  schema              = jsonencode(each.value.schema)
  clustering          = each.value.clustering
  description         = each.value.description
  deletion_protection = false

  dynamic "range_partitioning" {
    for_each = each.value.range_partitioning != null ? [each.value.range_partitioning] : []
    content {
      field = each.value.range_partitioning.field
      range {
        start    = each.value.range_partitioning.start
        end      = each.value.range_partitioning.end
        interval = each.value.range_partitioning.interval
      }
    }
  }


  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [each.value.time_partitioning] : []
    content {
      type                     = each.value.time_partitioning.type
      field                    = each.value.time_partitioning.field
      require_partition_filter = each.value.time_partitioning.require_partition_filter
    }
  }
  depends_on = [google_bigquery_dataset.datasets]
}