locals {
  directory             = "${local.configuration_folder}/sql_scripts/"
  sqlscr_file_extension = "yaml"
  job_query_files       = fileset(local.directory, "job_query_*.${local.sqlscr_file_extension}")
  sproc_files           = fileset(local.directory, "sproc_*.${local.sqlscr_file_extension}")
  udf_files             = fileset(local.directory, "udf_*.${local.sqlscr_file_extension}")

  job_query_configurations = {
    for job_query_file in local.job_query_files : replace(job_query_file, ".${local.sqlscr_file_extension}", "") =>
    yamldecode(file("${local.directory}/${job_query_file}"))
  }

  sproc_configurations = {
    for sproc_file in local.sproc_files : replace(sproc_file, ".${local.sqlscr_file_extension}", "") =>
    yamldecode(file("${local.directory}/${sproc_file}"))
  }

  udf_configurations = {
    for udf_file in local.udf_files : replace(udf_file, ".${local.sqlscr_file_extension}", "") =>
    yamldecode(file("${local.directory}/${udf_file}"))
  }
}


resource "google_bigquery_routine" "user_defined_function" {
  provider        = google-beta
  for_each        = local.udf_configurations
  dataset_id      = each.value.dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "SCALAR_FUNCTION"
  description     = lookup(each.value, "description", null)
  language        = each.value.language
  definition_body = each.value.definition_body

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
    }
  }

  return_type = each.value.return_type
}

resource "google_bigquery_routine" "stored_procedure" {
  provider        = google-beta
  for_each        = local.sproc_configurations
  dataset_id      = each.value.dataset_id
  routine_id      = each.value.routine_id
  routine_type    = "PROCEDURE"
  description     = lookup(each.value, "description", null)
  language        = lookup(each.value, "language", "SQL")
  definition_body = each.value.definition_body

  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])

    content {
      name          = arguments.value.name
      argument_kind = lookup(arguments.value, "argument_kind", null)
      data_type     = arguments.value.data_type
      mode          = lookup(arguments.value, "mode", null)
    }
  }

  depends_on = [google_bigquery_routine.user_defined_function]

}

resource "google_bigquery_job" "query" {
  provider = google-beta
  for_each = local.job_query_configurations
  job_id   = join("-", [each.value.job_id_prefix, uuid()])
  location = upper(local.multiregion)

  labels = {
    for label in lookup(each.value, "labels", {}) :
    label.key => label.value
  }

  query {
    query = each.value.query.query

    create_disposition = lookup(each.value.query, "create_disposition", null)
    write_disposition  = lookup(each.value.query, "write_disposition", null)

    dynamic "destination_table" {
      for_each = lookup(each.value.query, "destination_table", null) != null ? [each.value.query.destination_table] : []

      content {
        project_id = lookup(destination_table.value, "project_id", local.project)
        dataset_id = lookup(destination_table.value, "dataset_id", null)
        table_id   = destination_table.value.table_id
      }
    }

    dynamic "default_dataset" {
      for_each = lookup(each.value.query, "default_dataset", null) != null ? [each.value.query.default_dataset] : []

      content {
        project_id = lookup(default_dataset.value, "project_id", local.project)
        dataset_id = lookup(default_dataset.value, "dataset_id", null)
      }
    }

    dynamic "user_defined_function_resources" {
      for_each = lookup(each.value.query, "user_defined_function_resources", null) != null ? [each.value.query.user_defined_function_resources] : []

      content {
        resource_uri = lookup(user_defined_function_resources.value, "resource_uri", null)
        inline_code  = lookup(user_defined_function_resources.value, "inline_code", null)
      }
    }

    priority        = lookup(each.value.query, "priority", null)
    use_query_cache = lookup(each.value.query, "use_query_cache", null)

    use_legacy_sql = lookup(each.value.query, "use_legacy_sql", null)

    # legacy sql arguments
    allow_large_results = lookup(each.value.query, "allow_large_results", null)
    flatten_results     = lookup(each.value.query, "flatten_results", null)
    parameter_mode      = lookup(each.value.query, "parameter_mode", null)

    maximum_billing_tier = lookup(each.value.query, "maximum_billing_tier", null)
    maximum_bytes_billed = lookup(each.value.query, "maximum_bytes_billed", null)

    schema_update_options = lookup(each.value.query, "schema_update_options", null)
  }

  depends_on = [
    google_bigquery_routine.user_defined_function,
    google_bigquery_routine.stored_procedure
  ]
}

output "job_query_status" {
  value = tomap({
    for k, v in google_bigquery_job.query : k => v.status
  })
}
