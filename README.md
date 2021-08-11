# README - How to use Project template

## Purpose
The purpose of this repository is to explain how to use the Project Template to start your own project.


## Table of content

- [Prerequisites](#prerequisites)

- [Initialize the Project](#initialize-the-project)

- [Configure the Project](#configure-the-project)

- [Initialize the CICD](#initialize-the-cicd)

- [Example project](#example-project)
  * [Purpose](#purpose)
  * [Data for the tutorial](#data-for-the-tutorial)
  * [Steps to create the project](#steps-to-create-the-project)


<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>





## Prerequisites
1. Click on the green button "Use this template" on the [Project Template github page](https://github.com/loreal-datafactory/project-template) to create a new repository with the Project Template
2. Clone the created repository

> Note : Please start from the Project Template repository to get the latest features.
> This repository is based on an old version of the Project Template, its only purpose is to explain how to use the Project Template.

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
</br>

## Initialize the CICD

#### 1. Edit `environments/cicd.json`

```json
{
    "project": "<my-project-id>",
    "triggers_env": {
        "<my-env>": {
          "branch": "<my-branch>",
          "disabled": true|false
        }, ...
    },
    "pullrequest_env":"<my-env>",
    "owner":"<my-github-username>"
}
```

For example:
<details>
  <summary>Click to show example</summary>
  
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
</details></br>

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


## Example project

### Purpose

1. Create a workflow doing a join between Facts Table and Master Data Table
(Fact Table is in delta mode / Master Data Table is in Full).
This workflow have to be call each time an new delta is received for Fact table (or if the master data is updated)

2. Create an API (querying the resulting table)

### Data for the tutorial

1. worldcities.csv is a csv file containing a list of cities for the master table that was downloaded at [https://simplemaps.com/](https://simplemaps.com/)

2. fake_fact_table.csv contains the fake fact table generated by [`utils/generate_data/gen_data.py`](utils/generate_data/gen_data.py)

The data is currently stored here : [gs://howtoprojecttemplate-gcs-tuto-data/](https://console.cloud.google.com/storage/browser/howtoprojecttemplate-gcs-tuto-data).

### Steps to create the project

#### 1. Create a Bigquery dataset to store the tables

```shell
mkdir configuration/datasets/
vim configuration/datasets/<my-dataset>.yaml
```
Check [`configuration/datasets/tutodata.yaml`](configuration/datasets/tutodata.yaml) for an example configuration.

#### 2. Retrieve the created dataset ID and use it in the queries

#### 3. Create a Workflow

```shell
mkdir configuration/workflows/
vim configuration/workflows/<my-workflow>.yaml
```
Check [`configuration/workflows/load_data.yaml`](configuration/workflows/load_data.yaml) for an example workflow.
This workflow create 2 external tables (fact and master) linked to the 2 csv files and then create a result table by joining the 2 external tables.

#### 4. Create a Cloud function to run the Workflow and update the tables automatically

```shell
vim iac/<my-cloud-function>.tf
```
Check [`iac/functions.tf`](iac/functions.tf) for an example terrraform file for a cloud function.
The code executed by the cloud function is in `utils/cloud_functions/`, don't forget to zip it like this :
```shell
cd utils/could_functions/
zip run_workflow.zip main.py requirements.txt
```

[`main.py`](utils/could_functions/main.py) contains the python code executed by the cloud function.</br>
[`requirements.txt`](utils/could_functions/requirements.txt) contains the libraries needed to execute the code.

#### 5. Create an API for querying the result table
