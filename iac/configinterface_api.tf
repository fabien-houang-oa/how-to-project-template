locals {
  api_configuration_directory      = "${path.root}/configuration"
  api_configuration_file_extension = "json.tpl"
  api_domain                       = "//btdp-gcr-configinterface-${local.region_id}-${local.project_env}-${local.cloudrun_url_suffix}.a.run.app"

  raw_configurations = tolist([
    for tpl_configuration in fileset(local.api_configuration_directory, "configinterface_api/*.${local.api_configuration_file_extension}") :
    jsondecode(
      templatefile("${local.configuration_folder}/${tpl_configuration}",
        {
          "project" : local.project,
          "project_env" : local.project_env,
          "app_name" : local.app_name,
          "app_name_short" : local.app_name_short,
          "multiregion" : local.multiregion,
          "region" : local.region,
          "region_id" : local.region_id,
          "zone" : local.zone,
          "zone_id" : local.zone_id,
      })
    )
  ])

  flow_configurations = tolist([
    for tpl_configuration in fileset(local.api_configuration_directory, "flows/*.${local.api_configuration_file_extension}") : {
      path         = "/v1/flows"
      id_attribute = "data/id"
      data = {
        id = replace(basename(tpl_configuration), ".${local.api_configuration_file_extension}", "")
        steps = jsondecode(
          templatefile("${local.configuration_folder}/${tpl_configuration}",
            {
              "project" : local.project,
              "project_env" : local.project_env,
              "app_name" : local.app_name,
              "app_name_short" : local.app_name_short,
              "multiregion" : local.multiregion,
              "region" : local.region,
              "region_id" : local.region_id,
              "zone" : local.zone,
              "zone_id" : local.zone_id,
          })
        )
      }
    }
  ])

  statemachine_configurations = tolist([
    for tpl_configuration in fileset(local.api_configuration_directory, "state-machine/*.${local.api_configuration_file_extension}") : {
      path         = "/v1/state_machine/flows_actions"
      id_attribute = "data/flow_action_id"
      data = jsondecode(
        templatefile("${local.configuration_folder}/${tpl_configuration}",
          {
            "project" : local.project,
            "project_env" : local.project_env,
            "app_name" : local.app_name,
            "app_name_short" : local.app_name_short,
            "multiregion" : local.multiregion,
            "region" : local.region,
            "region_id" : local.region_id,
            "zone" : local.zone,
            "zone_id" : local.zone_id,
        })
      )
    }
  ])

  api_configurations = concat(local.raw_configurations, local.flow_configurations, local.statemachine_configurations)
}

# Create resource for REST API object flow
resource "restapi_object" "gcr_configinterface_api" {
  provider = restapi.gcr_configinterface_api

  count = length(local.api_configurations)
  path = join(
    "",
    [
      local.api_domain,
      local.api_configurations[count.index].path
    ]
  )
  data         = jsonencode(local.api_configurations[count.index].data)
  id_attribute = lookup(local.api_configurations[count.index], "id_attribute", null)

  create_method = lookup(local.api_configurations[count.index], "create_method", null)
  create_path = lookup(local.api_configurations[count.index], "create_path", null) != null ? join(
    "",
    [
      local.api_domain,
      lookup(local.api_configurations[count.index], "create_path", null)
    ]
  ) : null

  read_method = lookup(local.api_configurations[count.index], "read_method", null)
  read_path = lookup(local.api_configurations[count.index], "read_path", null) != null ? join(
    "",
    [
      local.api_domain,
      lookup(local.api_configurations[count.index], "read_path", null)
    ]
  ) : null

  update_method = lookup(local.api_configurations[count.index], "update_method", null)
  update_path = lookup(local.api_configurations[count.index], "update_path", null) != null ? join(
    "",
    [
      local.api_domain,
      lookup(local.api_configurations[count.index], "update_path", null)
    ]
  ) : null

  destroy_method = lookup(local.api_configurations[count.index], "destroy_method", null)
  destroy_path = lookup(local.api_configurations[count.index], "destroy_path", null) != null ? join(
    "",
    [
      local.api_domain,
      lookup(local.api_configurations[count.index], "destroy_path", null)
    ]
  ) : null
}

output "debug_configinterface_api" {
  value = local.api_configurations
}
