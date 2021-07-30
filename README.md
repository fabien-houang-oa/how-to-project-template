# README - How to use Project template

## Purpose
The purpose of this repository is to explain how to use the Project template to start your own project.


## Table of content



## Content




## Prerequisites
1. click on the green button "Use this template" on the [Project Template github page](https://github.com/loreal-datafactory/project-template) to create a new repository with the Project Template
2. clone the created repository


## Initialize the Project

- Modify `.app_name` file with your application name inside.

- Create a sandbox environment file (`sbx.json` for example) in `environments` folder with 

```json
{
    "project": "<my-project-id>"
}
```

- Specify the env and init:
> warning: ensure that the content of the `setup/init` directory matches your
> needs before executing the command. Adapt to your needs.

```shell
ENV=<my-env> make init
```

If your cloud build needs permissions to use cloud run, see how to set the permissions up in the [GCP doc](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#required_iam_permissions):

1. Open the [Cloud Build settings](https://console.cloud.google.com/cloud-build/settings/service-account) page in the Cloud Console
2. In the Service account permissions panel, set the status of the Cloud Run Admin role to ENABLED
3. In the Additional steps may be required pop-up, click on SKIP. Do NOT click on GRANT ACCESS TO ALL SERVICE ACCOUNTS
4. For increased security, grant the Service Account User role to only the Cloud Run Runtime Service Account. For instructions on doing this, see [Using minimal IAM permissions](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#continuous-iam).

## Configure the Project

- After having successfully initialize the project, go into the `configuration` folder and move all the folders with default example config files in an `examples/` folder:

```shell
mkdir configuration/examples/
mv configuration/* configuration/examples/
```

- Now, if you `ENV=<my-env> make iac-plan` without any config file, it should init terraform and should not offer you to create any additional resources.

- Base on the examples, create your own config files according to your needs:

For example if you need to create a dataset in Bigquery:
```shell
mkdir configuration/datasets/
vim configuration/datasets/<your-dataset>.yaml
```

Configure your `<your-dataset>.yaml` file base on the template in `configuration/examples/datasets/`

Same for configinterface_api, flows, matviews, sql_scripts, state-machine, tables, views, workflows, ...

- Modify terraform files in `iac/` folder according to the infrastructure you need for your project.

## Initialize the CICD


## Simple example project

### Purpose
1. Create a workflow doing a join between Facts Table and Master Data Table
(Fact Table is in delta mode / Master Data Table is in Full)

2. Create an API (querying the resulting table)

### Shared data for the tutorial

#### 1. Create a workflow