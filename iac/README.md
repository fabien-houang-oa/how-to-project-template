# README — `IaC`

- [README — `IaC`](#readme----iac-)
  * [Purpose](#purpose)
  * [Directory structure](#directory-structure)
  * [YAML configuration files](#yaml-configuration-files)
    + [`configinterface_api` subdirectory](#-configinterface-api--subdirectory)
    + [`sql-scripts` directory](#-sql-scripts--directory)
      - [Stored procedures](#stored-procedures)
      - [User-defined functions](#user-defined-functions)
      - [Jobs](#jobs)
        * [Query](#query)
        * [Copy](#copy)
        * [Extract](#extract)
        * [Load](#load)
    + [Configuration Directory](#Configuration-Directory)
      - [dataset](#dataset-subdirectory)
      - [tables](#tables-subdirectory)
      - [views](#views-subdirectory)
      - [matviews](#matviews-subdirectory)
    + [bigquery_structure file](#bigquery_structure)
    + [`matviews` subdirectory](#matviews-subdirectory))
    + [`workflows` directory](#workflows-directory)
      * [Library](#library)
      * [New workflow definition](#new-workflow-definition)
  * [How to deploy the IaC](#how-to-deploy-the-iac)


## Purpose

This README file aims to describe the content of the `iac` directory.

## Directory structure

This directory is a Terraform module that manages creation and deletion of:
  - API resource configurations
  - user-defined functions, stored procedures, and query jobs
```
.
<<<<<<< HEAD
├── configuration

.
├── locals.tf                               Contains the local terraform variables.
├── provider.tf                             Contains the terraform code to initialize the provider and default project.
├── sql-script.tf                           Contains the terraform code to create BigQuery routines.
├── bigquery_structure.tf                   Contains the terraform code to read config files and create variables for dataset, tables, views.
├── configinterface_api.tf                  Contains the terraform code to read configuration files for config-interface API.
├── module
  ├── bigquery_structure                    Contains the terraform files to create dataset, tables, views, materialized views permissions & tags.
    ├── datasets.tf                         Contains terraform code to create datasets, apply permissions.
    ├── tables.tf                           Contains terraform code to create tables.
    ├── views.tf                            Contains terraform code to create views and materialized views.
    ├── tags.tf                             Contains terraform code to apply tags for created datasets, tables, views.
    └── variables.tf                        Contains variables which will be injected from main.tf.
├── configuration                           Contains the configuration files for Datasets, tables, views, materialized views.
  ├── configinterface_api                   Contains the configuration files for configurations_api RAW files.
  ├── datasets                              Contains configuration for Datasets.
  ├── tables                                Contains configuration for tables.
  ├── views                                 Contains configuration for views.
  ├── matviews                              Contains configuration for materialized views
  ├── flows                                 Contains configuration for flows API.
  └── sql-scripts                           Contains the the configuration files for BigQuery routines.
├── workflows.tf                            Contains the terraform code to create workflows.
│── workflows                               Contains the configuration files for workflows.
│   ├──  Librairy                           Contains the common sub workflows to be used by developpers.
│   └── create_article.yaml                 An example of a main workflow added by a developper.
└── variables.tf                            Contains the Makefile injected terraform variables.
  - creation of datasets, tables, views, materialized views, permissions, tags

This directory is a Terraform module that manages creation of datasets, tables, views, materialized views, permissions, tags ,user-defined functions and stored procedures.
```

## Configuration files

This section gives a summary of the different configuration files subdirectories under `configuration`.

```
configuration                              Contains the configuration files subdirectories.
├── configinterface_api                    Contains the the configuration files for the Configuration Interface API endpoints.
├── datasets                              Contains configuration file for Datasets.
├── tables                                Contains configuration file for tables.
├── views                                 Contains configuration file for views.
├── matviews                              Contains configuration file for materialized views.
└── sql_scripts                            Contains the the configuration files for BigQuery jobs and routines.
```

### `configinterface_api` subdirectory

This subdirectory contains the configurations files for **Configuration Interface API** objects creation and management using the Terraform [**restapi** community provider](https://registry.terraform.io/providers/fmontezuma/restapi/latest/docs/resources/object) which is a fork (see [fmontezuma/terraform-provider-restapi](https://github.com/fmontezuma/terraform-provider-restapi)) of the original project on GitHub [Mastercard/terraform-provider-restapi](https://github.com/Mastercard/terraform-provider-restapi) that is not published on the Terraform registry.

See [README.md](configuration/configinterface_api/README.md) for more details.

### `sql_scripts` subdirectory

This subdirectory contains the configuration files for the BigQuery query jobs
(see [google_bigquery_job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_job#example-usage---bigquery-job-query)) and routines
(see [google_bigquery_routine](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_routine) terraform resource).

See [README.md](configuration/sql_scripts/README.md) for more details.
### `workflows` directory
The directory contains the main workflows yaml files to be added by the developper and also the librairy including the sub workflows to be imported into the final source.

### Library
The librairy contains the most common used sub workflows routines to be easily called by the main workflow added by the developper:
- `bq.yaml`: is a sub workflow encapsulating a new BigQuery job insertion to execute a specific query, using the V2 BigQuery API connector.
The parameters are dinamically setted based on main source call.
The returned result gives the final status of the execution and the related statistics.

- `monitoring.yaml`: is a sub workflow encapsulating the Pub/Sub call to track the execution's start and end of a given request.
The used arguments could be assigned during the main workflow definition or in the `workflow.tf` (in case of common values for the whole main workflow source).
The `start_publish_monitoring` and `end_publish_monitoring` steps are both preceded by an initializing step aiming to prepare the message to be sent into the related topic.

The sub workflows in the `Library` folder could be enhanced and also incremented, as we could notice the need of new common steps or new features / connectors releases.

### New workflow definition
The 2 files `create-article.yaml` and `create-product.yaml` are examples of added main workflows using the existing librairies:
- It should be named as the expected final created workflow.
- You should place the yaml file under the configuration/Workflows path (the sub folders creation is supported).
- The file name will be used as the flow id value as a monitoring parameter.
- Check the librairy folder to get the name of your required common steps.
- Check for the parmeters and add them to your arguments call.
- Deploy your work.

**Note: Currently workflow are available only in three regions [Workflow_regions](https://cloud.google.com/workflows/docs/locations). Make sure values are provided accordingly**

#### `dataset` subdirectory

This directory contains the dataset configuration files.

| Key | Description |
| ----| ------------- |
| dataset_id | dataset unique name [a-zA-Z], [0-9] or _ eg., APO, turnover etc., |
| description | dataset description |
| friendly name | name for dataset |
| criticity | provide data confidentiality c1, c2 or c3  (Default lower case) |
| location | provide dataset location, if not provided default value will be determined based on locals.tf file |
| data_domain | data domain name |
| domain_code | dataset domain-family code (maximum 3 characters, refer Referentials document in BTDP Sharepoint) |
| owned_by | Data product owner email address |
| delete_contents_on_destroy | true or false, if not provided default 'true' |
| delete_table_expiration_ms | Default null , Need to be filled only for temporary dataset. Should be provided only in milliseconds. If not default will be "432000000"(5 days) for temp. |
| permissions | List of owners, editors, viewers for each environment. Email address should be prefixed with user,service account or group  eg: "user:xyz@loreal.com", "serviceaccount:sa@loreal.com" , "group:group@loreal.com" |
| tags | provide entry tags. If user group needs to be added, provide environment (eg., dv, qa) and usergroup. For eg:   dv:            user_group: |

See example [dsdemo.yaml](configuration/datasets/dsdemo.yaml)
For detailed information refer [google_bigquery_dataset](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) terraform resource


#### `tables` subdirectory

This directory contains table configuration files.

| Key | Description |
| ----| ------------- |
| table_id | unique table ID in format 't/tb_tablename_Vn', where 'n' stands for table version 1,2 etc., valid characters: [a-zA-Z], [0-9] or _ |
| dataset | dataset unique name along with criticity and domain family code, it should match with related dataset information provided in datasets subdirectory. for eg: 'dsname_c1_101',without space |
| range_partitioning | provide range partitioning block with arguments field, start, end, interval, else null value |
| time_partitioning | provide time partitioning block with arguments type, field, require_partition_filter |
| clustering | provide clustering fields, else null value |
| description | description of table |
| gdpr | provide either true or false value, if not provided default will be false |
| privacy | provide either true or false value, if not provided default will be false |
| confidentiality | Either c1, c2 or c3 |
| data_domain | Domain Family name |
| data_family | domain-family code (maximum 3 characters, refer Referentials document in BTDP Sharepoint), for base layer value should be 'No data family in base layer' |
| data_gbo | provide for domain layer, for base layer value should be 'No gbo in base layer' |
| version | table version number based on table_id |
| previous_version | provide previous version table id if exist, else 0 |
| schema | table schema |

See example [t_dsdemo_v1.yaml](configuration/tables/t_dsdemo_v1.yaml)
For detailed information refer [google_bigquery_table](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) terraform resource

**Note: Tables with previous version should be handled carefully. If the config file for previous version table is unavailable, then the respective resources will not be created.** It is mandatory to maintain the config file for previous table versions atleast for 2 versions.


#### `views` subdirectory

This directory contains views configuration files.

| Key | Description |
| ----| ------------- |
| dataset | dataset unique name along with criticity, it should match with dataset description provided in datasets subdirectory. for eg: 'dsname_c1', name should be provided without space |
| view_id | view name 'v_name' valid characters: [a-zA-Z], [0-9] or _  |
| description | description of view |
| gdpr | provide either true or false value, if not provided default will be false |
| privacy | provide either true or false value, , if not provided default will be false |
| data_domain | Domain Family name |
| data_family | domain-family code (maximum 3 characters, refer Referentials document in BTDP Sharepoint) |
| confidentiality | Either c1, c2 or c3 |
| version | view version number |
| level | '0' or '1' , if no dependency on other view it is '0' else '1' if it depends on another one view. Currently in views.tf we have provided dependency check only till view level 1, if the view level has to be  increased, views.tf has to be adjusted accordingly |
| query | select query for the view; here project, location, env information of dataset will be variablized in main code |

See example [v_dsdemo.yaml](configuration/views/v_dsdemo.yaml)
For detailed information refer [google_bigquery_table](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) terraform resource


#### `matviews` subdirectory

Provide materialized configuration files in YAML format under this directory

| Key | Description |
| ----| ------------- |
| dataset | dataset unique name along with criticity, it should match with dataset description provided in datasets subdirectory. for eg: 'dsname_c1', name should be provided without space |
| table_id | materialized view name 'mv_name' valid characters: [a-zA-Z], [0-9] or _  |
| description | description of view |
| query | select query for the view; here project, location, env information of dataset will be variablized in main code |
| enableRefresh | true or false |
| refreshIntervalMs | provided only in milliseconds. If not default will be "3600000" |

See example [mv_dsdemo.yaml](configuration/matviews/mv_dsdemo.yaml)
For detailed information refer [google_bigquery_table](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) terraform resource

### module/bigquery_structure

This directory contains terraform code to create datatsets, tables, views, materialized views & tags based on bigquery resources.

# `bigquery_structure.tf`

In this the files provided under "Configuration" sub-directory will be decoded and constructs a tomap object for different configurations as required.

For datasets mapping, if any mandatory attribute values are missing it will replace with default values based on locals.tf file. Dataset ID will  be created dynamically here.

For tables, views, materialized views will be created only if respective datasets are available.

Mapped object values will be then ingested to the terraform files under iac/module/bigquery_structure/ directory.


## How to deploy the IaC

In the project root folder, run:
```shell
make iac-deploy
```
