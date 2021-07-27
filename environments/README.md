
# README — `Environments`

## Purpose

This README file aims to describe the content of the `environments` directory.

## Directory structure

This directory contains configurations files for the cicd and environment configuration files for sandbox and normalized environments.

```
.
├── cicd.json                           Contains the configuration for the cicd.
├── dv.json                             Contains the environment variables for the `dv` environment.
├── np.json                             Contains the environment variables for the `np` environment.
├── pd.json                             Contains the environment variables for the `pd` environment.
└── qa.json                             Contains the environment variables for the `qa` environment.
```

## JSON environment configuration files

Environment configuration files allows the definition of environments variables in different files.

Makefiles will load the corresponding environment configuration file depending on the value of the environment variables in the following order:
- `ENV`
- `SANDBOX_ENV` if `ENV` is not present

If neither `ENV` nor `SANBOX_ENV` are exported as environment variables in your shell and you don't want to export any of them,
you can set the environment variable for the scope of the call to the make command. For example:

 ```shell
 ENV=dv make all
 ```

For the sandbox environment, you can use one of the following command which are equivalent:

```shell
ENV=abc make all
```

or

```shell
SANDBOX_ENV=abc make all
```


### A. CICD configuration file

Check the CICD [README](../setup/cicd/README.md#modify-the-cicd-setup) to know how to modify the CICD configuration.


### A. Sandbox environment configuration file

For the sandbox environment you must create a `${SANDBOX_ENV}.json` file.

This file could be as minimal as:

```json
{
    "project": "<sandbox-project>"
}
```


### B. Normalized environments configuration files

For the normalized environments `dv`, `qa`, `np`, `pd`, `.json` template files are provided.
You must replace the values or delete the optionnal keys according to the table below.

For any normalized environment, the content of the `.json` environment files can be as minimal as:

```json
{
    "project_env": "<env>",
    "project": "<project>"
}
```

You can also override default values by specifying the following information:

```json
{
    "project_env": "<env>",
    "project": "<project>",
    "zone": "<zone>",
    "zone_id": "<zone_id>",
    "region": "<region>",
    "region_id": "<region_id>",
    "multiregion": "<multiregion>",
}
```

with:

| Key                            | Value         | Default value                               | Description                                                                          |
|--------------------------------|---------------|---------------------------------------------|--------------------------------------------------------------------------------------|
| "project"                      | **Mandatory** | none                                        | the project name                                                                     |
| "project_env"                  | **Optional**  | _file_name_ (without the `.json` extension) | the environment (`dv`, `qa`, `np`, `pd`) or the sandbox environment (e.g `abc`)      |
| "zone"                         | **Optional**  | `europe-west1-b`                            | the zone, e.g. `europe-west1-b`                                                      |
| "zone_id"                      | **Optional**  | _computed from "zone"_                      | the zone identifier, e.g. `ew1b`                                                     |
| "region"                       | **Optional**  | _computed from "zone"_                      | the region, e.g. `europe-west1`                                                      |
| "region_id"                    | **Optional**  | _computed from "zone_id"_                   | the region identifier, e.g. `ew1`                                                    |
| "multiregion"                  | **Optional**  | _computed from "zone"_                      | the multiregion, e.g. `us` or `eu`                                                   |

Note: Optional keys can be omitted. However, you must ensure that it is handled properly in the Terraform configuration using for example `lookup` with a default value.