# =================================================================== #
#                  __  __      _        __ _ _
#                 |  \/  |__ _| |_____ / _(_) |___
#                 | |\/| / _` | / / -_)  _| | / -_)
#                 |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# =================================================================== #
# -- < Global configuration > --
# =================================================================== #
SHELL := /bin/bash

.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL    := help
CURRENT_MAKEFILE := $(lastword $(MAKEFILE_LIST))


# ---------------------------------------------------------------------------------------- #
# -- < Initla Check for Env > --
# ---------------------------------------------------------------------------------------- #

ENV ?= $(SANDBOX_ENV)

ifeq ($(ENV),)
$(error ENV is not set)
endif
$(info "ENV = $(ENV)")

ENV_FILE:=$(shell ls environments/$(ENV).json)
$(info "ENV_FILE = $(ENV_FILE)")
ifeq ($(ENV_FILE),)
$(error ENV $(ENV): env file not found)
endif


# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
PYTHON_BIN := python3.8

# -- compute application variables
APP_NAME        ?= $(shell cat .app_name)
$(info "APP_NAME = $(APP_NAME)")
APP_NAME_SHORT  := $(shell sed 's/-//g' <<< "$(APP_NAME)")
$(info "APP_NAME_SHORT = $(APP_NAME_SHORT)")

# -- load variables from ENV
PROJECT := $(shell cat $(ENV_FILE) | jq -r '.project')
$(info "PROJECT = $(PROJECT)")
PROJECT_ENV := $(shell cat $(ENV_FILE) | jq -r '.| if has("project_env") then .project_env else "$(ENV)" end')
ZONE := $(shell cat $(ENV_FILE) | jq -r '.| if has("zone") then .zone else "europe-west1-b" end')
REGION := $(shell cat $(ENV_FILE) | jq -r '.| if has("region") then .region else ("$(ZONE)"|sub("-[a-z]$$"; "")) end')
$(info "REGION = $(REGION)")
$(info "PROJECT_ENV = $(PROJECT_ENV)")


# -- bucket definitions
DEPLOY_BUCKET   ?= $(APP_NAME_SHORT)-gcs-deploy-eu-$(PROJECT_ENV)
$(info "DEPLOY_BUCKET = $(DEPLOY_BUCKET)")


# -- compute module variables
MODULES_DIR      = $(filter %/, $(wildcard modules/*/))
MODULES          = $(sort $(MODULES_DIR:modules/%/=%))
$(info "MODULES = $(MODULES)")

# -- determine code branch
BRANCH ?= $(shell \
	if [ "$(BRANCH_NAME)" != "" ]; then \
		echo -n "${BRANCH_NAME}"; \
	else \
		git rev-parse --abbrev-ref HEAD || echo -n "current" ; \
	fi;)
$(info "BRANCH = $(BRANCH)")



# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# ---------------------------------------------------------------------------------------- #
.PHONY: help all clean iac-deploy test build deploy $(MODULES)


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
all             Runs the all target on every module of the modules subdirectory
test            Runs the application by launching unit tests
build           Builds the application by producing artefacts (archives, docker images, etc.)
clean           Cleans the generated intermediary files
iac-init        Initializes the terraform infrastructure
iac-prepare     Prepares the terraform infrastructure by create the variable files
iac-plan        Produces the terraform plan to visualize what will be changed in the infrastructure
iac-deploy      Proceeds to the application of the terraform infrastructure
iac-clean       Cleans the intermediary terraform files to restart the process
deploy          Pushes the application artefact and deploys it by applying the terraform
reinit          Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "Welcome to the main help"
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


# ---------------------------------------------------------------------------------------- #
# This target will perform a complete installation of the current repository.
# ---------------------------------------------------------------------------------------- #
all: $(MODULES)


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the cleaning of the current parent
clean: iac-clean

# -- this target will trigger the cleaning of the desired module
clean-module-%:
	@$(MAKE) -f ../../module.mk -C modules/$* -$(MAKEFLAGS) clean MODULE_NAME=$*

# -- this target will trigger the cleaning of the parent, its modules and so on
.PHONY: clean-all
clean-all: clean $(foreach mod, $(MODULES), clean-module-$(mod))


# -- this target will trigger the cleaning of the git repository, thus all untracked files
# will be deleted, so beware.
.PHONY: reinit
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)


# ---------------------------------------------------------------------------------------- #
# -- < Modules > --
#
# This target will trigger the execution of make in a recursive way by calling make for
# each element of the target that is a module declared in 'modules' subdirectory.
#
# ---------------------------------------------------------------------------------------- #
$(MODULES):
	@echo "Calling make for $@"
	@$(MAKE) -f ../../module.mk -C modules/$@ -$(MAKEFLAGS) all MODULE_NAME=$@


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = iac/.terraform/terraform.tfstate
TF_VARS  = iac/terraform.tfvars
TF_PLAN  = iac/tfplan
TF_STATE = $(wildcard iac/*.tfstate iac/.terraform/*.tfstate)
TF_FILES = $(wildcard iac/*.tf)


# -- internal definition for easing changes
define HERE_TF_VARS
app_name          = "$(APP_NAME)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
deploy_bucket     = "$(DEPLOY_BUCKET)"
env_file          = "../$(ENV_FILE)"
endef
export HERE_TF_VARS


# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@if [ ! -d iac ]; then \
		echo "[iac-init] :: no infrastructure"; \
	else \
		cd iac; \
		if [ ! -d .terraform ]; then \
			function remove_me() { if (( $$? != 0 )); then rm -fr .terraform; fi; }; \
			trap remove_me EXIT; \
			echo "[iac-init] :: initializing terraform"; \
			terraform init \
				-backend-config=bucket=$(DEPLOY_BUCKET) \
				-backend-config=prefix=terraform-state/global \
				-input=false; \
		else \
			echo "[iac-init] :: terraform already initialized"; \
		fi; \
	fi;

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS)  # provided for convenience
$(TF_VARS): $(TF_INIT)
	@if [ -d iac ]; then \
		echo "[iac-prepare] :: generation of $(TF_VARS) file"; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		echo 'cloudrun_url_suffix = "$(shell \
			gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION))"' \
			>> $(TF_VARS); \
		echo "[iac-prepare] :: generation of $(TF_VARS) file DONE."; \
	else \
		echo "[iac-prepare] :: no infrastructure"; \
	fi;

# -- this target will create the iac/tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f iac/tfplan
iac-plan: $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@set -euo pipefail; \
	if [ -d iac ]; then \
		echo "[iac-plan] :: planning the iac in $(PROJECT) ($(PROJECT_ENV))"; \
		cd iac && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN)); \
		echo "[iac-plan] :: planning the iac for $(APP_NAME) DONE."; \
	else \
		echo "[iac-plan] :: no infrastructure"; \
	fi;

# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: $(TF_PLAN)
	@echo "[$@] :: launching the parent iac target on $(APP_NAME)"
	@if [ -d iac ]; then \
		cd iac; \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN)); \
	else \
		echo "[$@] :: no infrastructure"; \
	fi;
	@echo "[$@] :: is finished on $(APP_NAME)"

# -- this target will trigger the iac of the desired module
iac-deploy-module-%:
	@$(MAKE) -f ../../module.mk -C modules/$* -$(MAKEFLAGS) iac-deploy MODULE_NAME=$*

# -- this target will trigger the iac of the parent, its modules and so on
.PHONY: iac-deploy-all
iac-deploy-all: iac-deploy $(foreach mod, $(MODULES), iac-deploy-module-$(mod))


# -- this target will clean the intermediary iac files
# might need to delete the iac/.terraform/terraform.tfstate file
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning Iac intermediary files : '$(TF_PLAN), $(TF_VARS)'"
	@if [ -d iac ]; then \
		rm -fr $(TF_PLAN) $(TF_VARS) iac/.terraform; \
	fi;
	@$(info "$@ :: cleaning Iac intermediary files DONE.")


#-----------------------------------------------------------------------------------------#
#                               -- SETUP: CICD & Init --
#-----------------------------------------------------------------------------------------#
.PHONY: cicd
cicd:
	@$(MAKE) ENV=cicd -C setup/cicd all

.PHONY: gcb-cicd
gcb-cicd:
	tmp_file="cloudbuild-cicd.yaml" \
		&& echo -e "steps:\n- id: CICD deploy\n  name: gcr.io/itg-btdpshared-gbl-ww-pd/generic-build\n  entrypoint: make\n  args:\n  - ENV=cicd\n  - cicd" >"$${tmp_file}" \
		&& gcloud --project $(shell cat environments/cicd.json | jq -r '.project') \
			builds submit --config "$${tmp_file}" \
		&& rm -f "$${tmp_file}" || rm -f "$${tmp_file}";

.PHONY: init
init:
	@$(MAKE) ENV=$(ENV) -C setup/init all

# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the testing of the current parent
.PHONY: test
test: # provided for convenience

# -- this target will trigger the testing of the desired module
test-module-%:
	@$(MAKE) -f ../../module.mk -C modules/$* -$(MAKEFLAGS) test MODULE_NAME=$*

# -- this target will trigger the testing of the parent, its modules and so on
test-all: test $(foreach mod, $(MODULES), test-module-$(mod))


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the build of the current parent
.PHONY: build
build: # provided for convenience

# -- this target will trigger the build of the desired module
build-module-%:
	@$(MAKE) -f ../../module.mk -C modules/$* -$(MAKEFLAGS) build MODULE_NAME=$*

# -- this target will trigger the build of the parent, its modules and so on
.PHONY: build-all
build-all: build $(foreach mod, $(MODULES), build-module-$(mod))

# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
#
# Targets are used to perform the deployment of both the main parent and its modules.
# ---------------------------------------------------------------------------------------- #
# -- this target will trigger only the deployment of the current parent
.PHONY: deploy
deploy: iac-plan-clean iac-deploy

# -- this target will trigger the deployment of the desired module
deploy-module-%:
	@$(MAKE) -f ../../module.mk -C modules/$* -$(MAKEFLAGS) deploy MODULE_NAME=$*

# -- this target will trigger the deployment of the parent, its modules and so on
.PHONY: deploy-all
deploy-all: deploy $(foreach mod, $(MODULES), deploy-module-$(mod))

# ---------------------------------------------------------------------------------------- #
# -- < Include Custom makefile > --
# ---------------------------------------------------------------------------------------- #
-include custom.mk
