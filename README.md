# README - How to use Project template

## Purpose
The purpose of this repository is to explain how to use the Project Template to start your own project.


## Table of content



## Content




## Prerequisites
1. Click on the green button "Use this template" on the [Project Template github page](https://github.com/loreal-datafactory/project-template) to create a new repository with the Project Template
2. Clone the created repository


## Initialize the Project

#### 1. Modify `.app_name` file with your application name, recommend to use your github repository name.

#### 2. Create a sandbox environment file `<my-env>.json` (`sbx.json` for example) in `environments/` folder with 

```json
{
    "project": "<my-project-id>"
}
```
Replace `<my-project-id>` by your GCP project ID

#### 3. Specify the env and init:
> warning: ensure that the content of the `setup/init/` directory matches your
> needs before executing the command. Adapt to your needs.

```shell
ENV=<my-env> make init
```
Replace `<my-env>` by `sbx` if your environment file is `sbx.json`

If your cloud build needs permissions to use cloud run, see how to set the permissions up in the [GCP doc](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#required_iam_permissions):

1. Open the [Cloud Build settings](https://console.cloud.google.com/cloud-build/settings/service-account) page in the Cloud Console
2. In the Service account permissions panel, set the status of the Cloud Run Admin role to ENABLED
3. In the Additional steps may be required pop-up, click on SKIP. Do NOT click on GRANT ACCESS TO ALL SERVICE ACCOUNTS
4. For increased security, grant the Service Account User role to only the Cloud Run Runtime Service Account. For instructions on doing this, see [Using minimal IAM permissions](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#continuous-iam).


## Configure the Project

#### 1. After having successfully initialize the project, go into the `configuration/` folder and move all the folders with the default config files in an `examples/` folder:

```shell
mkdir configuration/examples/
mv configuration/* configuration/examples/
```

#### 2. Now, run `ENV=<my-env> make iac-plan`
It should init terraform and should not offer you to create any additional resources.

#### 3. Base on the examples, create your own config files according to your needs:

For example if you need to create a dataset in Bigquery:
```shell
mkdir configuration/datasets/
vim configuration/datasets/<my-dataset>.yaml
```

Configure your `<my-dataset>.yaml` file base on the template file in `configuration/examples/datasets/`

Same for configinterface_api, flows, matviews, sql_scripts, state-machine, tables, buckets, views, workflows, ...

#### 4. Modify terraform files in `iac/` folder according to the infrastructure you need for your project.

#### 5. Use `ENV=<my-env> make iac-clean`, `ENV=<my-env> make iac-plan` and `ENV=<my-env> make iac-deploy` to clean, plan and deploy your resources.


## Initialize the CICD

#### 1. Edit `environments/cicd.json`

```json
{
    "project": "<my-project-id>",
    "triggers_env": {
        "<my-env>": {
          "branch": "<my-branch>",
          "disabled": true|false
        }
    },
    "pullrequest_env":"<my-env>",
    "owner":"<my-github-username>"
}
```

For example:
```json
{
    "project": "btdp-sbx-f-houang",
    "triggers_env": {
        "sbx": {
          "branch": "develop",
          "disabled": true
        }
    },
    "pullrequest_env":"sbx",
    "owner":"fabien-houang-oa"
}
```

#### 2. In `setup/cicd/`, modify Makefile to suit your needs

#### 3. In `setup/cicd/`, modify Terraform files to suit your needs

#### 4. Init cicd

```shell
cd setup/cicd/
ENV=cicd make all
```

or from the root repo
```shell
ENV=cicd make cicd
```

or from root with cloud build
```shell
ENV=cicd make gcb-cicd
```

if you encounter this error while trying to create triggers :
```shell
Error creating Trigger: googleapi: Error 400: Repository mapping does not exist. Please visit <link>
```
Follow the link and connect your github repository to Cloud Build



## Simple example project

### Purpose

1. Create a workflow doing a join between Facts Table and Master Data Table
(Fact Table is in delta mode / Master Data Table is in Full).
This workflow have to be call each time an new delta is received for Fact table (or if the master data is updated)

2. Create an API (querying the resulting table)

### Shared data for the tutorial

#### 1. Create a workflow