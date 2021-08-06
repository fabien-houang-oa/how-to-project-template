# README — `configinterface_api`

## Purpose

This README file aims to describe the content of the `configinterface_api` directory which contains **JSON** configuration template files.

## Directory structure

This directory contains the configurations files for REST API objects creation and management using the Terraform [**restapi** community provider](https://registry.terraform.io/providers/fmontezuma/restapi/latest/docs/resources/object) which is a fork (see [fmontezuma/terraform-provider-restapi](https://github.com/fmontezuma/terraform-provider-restapi)) of the original project on GitHub [Mastercard/terraform-provider-restapi](https://github.com/Mastercard/terraform-provider-restapi) that is not published on the Terraform registry.

```
.
├── flows_example.json.tpl                    An example of Flows endpoint configuration file to manage a flow.
└── statemachine_example.json.tpl             An example of StateMachine endpoint configuration file to manage state_machine.
```

API flows configuration template files are used to create `restapi_object` Terraform resources which allows the following operation are possibles on an object:
- create using the `POST` method
- read using the `GET` method
- update (as replace) using the `PUT` method
- update (as modify) using the `PATCH` method
- destroy using the `DELETE` method

Any variable reference (typically local variables related to app_name, locations related local variables, etc...) in the template files will be replaced by its value before being parsed as a JSON object to create resources. See the examples template files.

The configuration template files, have the following key-value pairs:

| Key                            | Description                                                                                             |
|--------------------------------|---------------------------------------------------------------------------------------------------------|
| data                           | the request body to be used for create and update methods as a JSON object literal (**required**)       |
| domain                         | the domain prefixed with `//`, e.g. `//example.com` (**required**)                                      |
| path                           | the default path to the API endpoint (**required**)                                                     |
| id_attribute                   | the id attribute, i.e. the key, of the object id (**optional**, defaults to `id`)                       |
| create_path                    | the create path (**optional**, defaults to `path`)                                                      |
| read_path                      | the read path (**optional**, defaults to `path/{id}`)                                                   |
| update_path                    | the update path (**optional**, defaults to `path/{id}`)                                                 |
| destroy_path                   | the destroy path (**optional**, defaults to `path/{id}`)                                                |
| create_method                  | the create method, usually `POST` (**optional**, defaults to `POST`)                                    |
| read_method                    | the read method, usually `GET` (**optional**, defaults to `GET`)                                        |
| update_method                  | the update method, usually `PUT` or `PATCH` (**optional**, defaults to `PUT`)                           |
| destroy_method                 | the destroy method, usually `DELETE` (**optional**, defaults to `DELETE`)                               |

More details and optional fields can be found in the [object.md](https://github.com/Mastercard/terraform-provider-restapi/blob/master/docs/resources/object.md) document of the official project.