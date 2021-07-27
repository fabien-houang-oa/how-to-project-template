locals {

  #look for datasets config yaml file
  tpl_datasets = fileset("${local.configuration_folder}/datasets/", "*.yaml")
  config_datasets = [for dataset in local.tpl_datasets : merge(yamldecode(file("${local.configuration_folder}/datasets/${dataset}")),
    {
      description = replace(dataset, ".yaml", "")
    }
    )
  ]

  #look for tables config yaml file
  tpl_tables = fileset("${local.configuration_folder}/tables/", "*.yaml")
  config_tables = [for table in local.tpl_tables : merge(yamldecode(file("${local.configuration_folder}/tables/${table}")), {
    description = replace(table, ".yaml", "")
    }
    )
  ]

  #look for Views config yaml file
  tpl_views = fileset("${local.configuration_folder}/views/", "*.yaml")
  config_views = [for views in local.tpl_views : merge(yamldecode(file("${local.configuration_folder}/views/${views}")), {
    description = replace(views, ".yaml", "")
    }
    )
  ]

  #look for materialized views yaml file
  materialized_views = fileset("${local.configuration_folder}/matviews/", "*.yaml")
  config_mviews = [for views in local.materialized_views : merge(yamldecode(file("${local.configuration_folder}/matviews/${views}")), {
    description = replace(views, ".yaml", "")
    }
    )
  ]

  #Read config from yaml file and fill missing values with default one
  dataset_output = [
    for dataset in local.config_datasets : {
      project                     = lookup(dataset, "project", local.project)
      dataset_id                  = length(regexall("(tmp)$", dataset.dataset_id)) == 0 ? "${local.app_name_short}_ds_${lookup(dataset, "criticity", "c3")}_${lookup(dataset, "domain_code", null)}_${replace(dataset.dataset_id, " ", "")}_${lookup(dataset, "location", local.multiregion)}_${local.project_env}" : "${local.app_name_short}_ds_${lookup(dataset, "criticity", "c3")}_${lookup(dataset, "domain_code", null)}_${trimsuffix(replace(dataset.dataset_id, " ", ""), "_tmp")}_${lookup(dataset, "location", local.multiregion)}_${local.project_env}_tmp"
      location                    = lookup(dataset, "location", local.multiregion)
      confidentiality             = lookup(dataset, "criticity", "c3")
      description                 = dataset.description
      friendly_name               = dataset.friendly_name
      data_domain                 = dataset.data_domain
      owned_by                    = dataset.owned_by
      delete_contents_on_destroy  = lookup(dataset, "delete_contents_on_destroy", "true")
      default_table_expiration_ms = length(regexall("(tmp)$", dataset.dataset_id)) == 0 ? null : lookup(dataset, "default_table_expiration_ms", "432000000")
      dataset_unique              = "${lookup(dataset, "dataset_id", "")}_${lookup(dataset, "criticity", "c3")}_${lookup(dataset, "domain_code", null)}"
      tags                        = lookup(dataset, "tags", [])
    }
  ]

  #convert the values into map format
  dataset_map = ({
    for dataset in local.dataset_output :
    dataset.dataset_unique => dataset
  })

  #get permissions from dataset config file
  permissions_output = [
    for dataset in local.config_datasets : {
      project             = lookup(dataset, "project", local.project)
      dataset_id          = length(regexall("(tmp)$", dataset.dataset_id)) == 0 ? "${local.app_name_short}_ds_${lookup(dataset, "criticity", "c3")}_${lookup(dataset, "domain_code", null)}_${replace(dataset.dataset_id, " ", "")}_${lookup(dataset, "location", local.multiregion)}_${local.project_env}" : "${local.app_name_short}_ds_${lookup(dataset, "criticity", "c3")}_${lookup(dataset, "domain_code", null)}_${trimsuffix(replace(dataset.dataset_id, " ", ""), "_tmp")}_${lookup(dataset, "location", local.multiregion)}_${local.project_env}_tmp"
      description         = dataset.description
      dataset_permissions = lookup(dataset, "dataset_permissions", [])
    }
  ]

  #convert the values into map format
  permissions_map = ({
    for permission in local.permissions_output :
    permission.dataset_id => permission
  })

  #get tags from dataset config file
  tags_output = [
    for dataset in local.dataset_output : {
      project        = dataset.project
      dataset_id     = dataset.dataset_id
      description    = dataset.description
      layer          = length(dataset.tags) >= 1 ? dataset.tags.layer : ""
      entry_group_id = length(dataset.tags) >= 1 ? dataset.tags.entry_group_id : ""
      env            = length(dataset.tags) >= 1 ? lookup(dataset.tags, local.project_env, []) : []
    }
  ]
  #convert the values into map format
  tags_map = ({
    for tags in local.tags_output :
    tags.dataset_id => tags
  })
  #Scan table config and create a list
  table_list = [for table in local.config_tables : "${lookup(local.dataset_map, table.dataset).project}.${lookup(local.dataset_map, table.dataset).dataset_id}.${table.table_id}"]

  #Read config from tables yaml file and create only if dataset exist
  table_output = [
    for table in local.config_tables : {
      dataset_id         = lookup(local.dataset_map, table.dataset).dataset_id
      project            = lookup(local.dataset_map, table.dataset).project
      previous_version   = table.previous_version == 0 ? true : (contains(local.table_list, "${lookup(local.dataset_map, table.dataset).project}.${lookup(local.dataset_map, table.dataset).dataset_id}.${table.previous_version}"))
      range_partitioning = table.range_partitioning
      clustering         = toset(table.clustering)
      description        = table.description
      schema             = table.schema
      table_id           = table.table_id
      time_partitioning  = table.time_partitioning
      gdpr               = lookup(table, "gdpr", "false")
      privacy            = lookup(table, "privacy", "false")
      confidentiality    = table.confidentiality
      data_domain        = table.data_domain
      data_family        = table.data_family
      data_gbo           = table.data_gbo
      version            = table.version
    }
  ]

  #convert the values into map format
  table_map = tomap({
    for table in local.table_output :
    table.table_id => table
  })


  #Read config from views yaml file and create only if dataset exist
  view_output = [
    for views in local.config_views : {
      dataset_id      = lookup(local.dataset_map, views.dataset).dataset_id
      view_id         = views.view_id
      query           = replace(replace(replace(views.query, "project", lookup(local.dataset_map, views.dataset).project), "env", local.project_env), "location", lookup(local.dataset_map, views.dataset).location)
      data_domain     = views.data_domain
      data_family     = views.data_family
      description     = views.description
      confidentiality = views.confidentiality
      version         = views.version
      privacy         = lookup(views, "privacy", "false")
      gdpr            = lookup(views, "gdpr", "false")
      project         = lookup(local.dataset_map, views.dataset).project
      level           = views.level

    }
  ]
  #convert the values into map format
  view_map = tomap({
    for views in local.view_output :
    views.view_id => views
  })

  #Read config for materialized view from yaml file and create only if dataset exist.
  mview_output = [
    for mviews in local.config_mviews : {
      dataset_id          = lookup(local.dataset_map, mviews.dataset).dataset_id
      table_id            = mviews.table_id
      query               = replace(replace(replace(replace(mviews.query, "project", lookup(local.dataset_map, mviews.dataset).project), "env", local.project_env), "location", lookup(local.dataset_map, mviews.dataset).location), "dataset", lookup(local.dataset_map, mviews.dataset).dataset_id)
      description         = mviews.description
      enable_refresh      = mviews.enableRefresh
      refresh_interval_ms = lookup(mviews, "refreshIntervalMs", "3600000")
      project             = lookup(local.dataset_map, mviews.dataset).project

    }
  ]

  #convert into map format
  mview_map = tomap({
    for views in local.mview_output :
    views.table_id => views
  })


}

module "bigquery_structure" {
  source      = "./module/bigquery_structure"
  project_env = local.project_env
  project     = local.project
  location    = local.multiregion
  region      = local.region
  datasets    = local.dataset_map
  tables      = local.table_map
  permissions = local.permissions_map
  views       = local.view_map
  mat_views   = local.mview_map
  tags        = local.tags_map
}
