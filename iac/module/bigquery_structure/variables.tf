locals {
  project = var.project
}

variable "location" {
  type = string
}

variable "region" {
  type = string
}


variable "project_env" {
  type = string
}

variable "project" {
  type = string
}

variable "datasets" {
  default = {}
  type = map(object({
    dataset_id                  = string,
    project                     = string,
    friendly_name               = string,
    description                 = string,
    location                    = string,
    data_domain                 = string,
    owned_by                    = string,
    confidentiality             = string,
    delete_contents_on_destroy  = bool,
    default_table_expiration_ms = number,
  }))
}

variable "tables" {
  default = {}
  type = map(object({
    dataset_id         = string,
    project            = string,
    description        = string,
    clustering         = any,
    schema             = list(any),
    table_id           = string,
    time_partitioning  = list(any),
    range_partitioning = list(any),
    privacy            = bool,
    gdpr               = bool,
    data_domain        = string,
    data_family        = string,
    data_gbo           = string,
    confidentiality    = string,
    version            = number,
    previous_version   = bool
  }))
}


variable "permissions" {
  default = {}
  type = map(object({
    dataset_id          = string,
    project             = string,
    dataset_permissions = any,
  }))
}



variable "views" {
  default = {}
  type = map(object({
    dataset_id      = string,
    view_id         = string,
    query           = string,
    privacy         = bool,
    gdpr            = bool,
    data_domain     = string,
    data_family     = string,
    description     = string,
    confidentiality = string,
    version         = number,
    level           = number,
    project         = string
  }))
}

variable "mat_views" {
  default = {}
  type = map(object({
    dataset_id          = string,
    table_id            = string,
    description         = string,
    enable_refresh      = string,
    project             = string,
    query               = string,
    refresh_interval_ms = number
  }))
}

variable "tags" {
  default = {}
  type = map(object({
    dataset_id     = string,
    description    = string,
    project        = string,
    layer          = string,
    entry_group_id = string,
    env            = any
  }))
}