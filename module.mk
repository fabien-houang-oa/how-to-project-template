# ======================================================================================== #
#            __  __         _      _       __  __      _        __ _ _
#           |  \/  |___  __| |_  _| |___  |  \/  |__ _| |_____ / _(_) |___
#           | |\/| / _ \/ _` | || | / -_) | |\/| / _` | / / -_)  _| | / -_)
#           |_|  |_\___/\__,_|\_,_|_\___| |_|  |_\__,_|_\_\___|_| |_|_\___|
#
# ======================================================================================== #
# -- < Global configuration > --
# ======================================================================================== #
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

ENV_FILE:=$(shell ls ../../environments/$(ENV).json)
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
$(info "PROJECT_ENV = $(PROJECT_ENV)")
ZONE := $(shell cat $(ENV_FILE) | jq -r '.| if has("zone") then .zone else "europe-west1-b" end')
REGION := $(shell cat $(ENV_FILE) | jq -r '.| if has("region") then .region else ("$(ZONE)"|sub("-[a-z]$$"; "")) end')
$(info "REGION = $(REGION)")
APIGEE_ENDPOINT := $(shell jq -r '.APIGEE_ENDPOINT' $(ENV_FILE))
$(info "APIGEE_ENDPOINT = $(APIGEE_ENDPOINT)")
APIGEE_ENV := $(shell jq -r '.APIGEE_ENV' $(ENV_FILE))
$(info "APIGEE_ENV = $(APIGEE_ENV)")
APIGEE_ORG := $(shell jq -r '.APIGEE_ORG' $(ENV_FILE))
$(info "APIGEE_ORG = $(APIGEE_ORG)")


# -- bucket definitions
DEPLOY_BUCKET   ?= $(APP_NAME_SHORT)-gcs-deploy-eu-$(PROJECT_ENV)
$(info "DEPLOY_BUCKET = $(DEPLOY_BUCKET)")

# -- compute module variables
MODULE_NAME          ?= $(shell basename ${PWD})
override MODULE_NAME := $(shell sed -E 's/^([0-9]+[-])?//' <<< "$(MODULE_NAME)")
$(info "MODULE_NAME = $(MODULE_NAME)")
MODULE_NAME_SHORT    := $(shell sed 's/-//g' <<< "$(MODULE_NAME)")
$(info "MODULE_NAME_SHORT = $(MODULE_NAME_SHORT)")
TYPE                 ?= gcr
$(info "TYPE = $(TYPE)")


# ---------------------------------------------------------------------------------------- #
# -- < Targets > --
# ---------------------------------------------------------------------------------------- #
# target .PHONY for defining elements that must always be run
# ---------------------------------------------------------------------------------------- #
.PHONY: help all clean iac-deploy test build deploy


# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
all             Run the following targets at once : iac-clean prepare-test build iac-init deploy
test            Tests the application by launching unit tests
build           Builds the application by producing artefacts (archives, docker images, etc.)
clean           Cleans the generated intermediary files
iac-init        Initializes the terraform infrastructure
iac-prepare     Prepares the terraform infrastructure by create the variable files
iac-plan        Produces the terraform plan to visualize what will be changed in the infrastructure
iac-deploy      Proceeds to the application of the terraform infrastructure
iac-clean       Cleans the intermediary terraform files to restart the process
deploy-app      Pushes the application artefact
deploy          Pushes the application artefact and deploys it by applying the terraform
reinit          Remove untracked files from the current git repository
endef
export HERE_HELP

help:
	@echo "Launching the Makefile help"
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""


all: clean prepare-test build deploy
	@echo "Makefile launched in $(shell basename ${PWD}) for $(MODULE_NAME)"


# ---------------------------------------------------------------------------------------- #
# -- < Cleaning > --
# ---------------------------------------------------------------------------------------- #
clean: clean-app iac-clean
	@echo "Cleaning module $(MODULE_NAME)"


# -- this target will trigger the cleaning of the git repository, thus all untracked files
# will be deleted, so beware.
reinit:
	@git clean -f $(shell pwd)
	@git clean -fX $(shell pwd)


# ---------------------------------------------------------------------------------------- #
# -- < Testing > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcc)
PYTHON_SRC        := dags
else
PYTHON_SRC        := src
endif

SRC_FILES          = $(shell find $(PYTHON_SRC) -type f \
						-not \( -name *.pyc -o -name *_test.py -o -name conftest.py \) )
TEST_FILES         = $(shell find $(PYTHON_SRC) -type f \
						\( -name "*_test.py" -o -name conftest.py \) )
TEST_ENV           = test_env.sh
VIRTUAL_ENV        = .venv
BUILD_REQUIREMENTS = requirements.txt
TESTS_REQUIREMENTS = requirements-test.txt

PYLINTRC_LOCATION   = ../../.pylintrc
COVERAGERC_LOCATION = ../../.coveragerc


define HERE_TESTS_REQUIREMENTS
pytest==6.2.1
pytest-cov==2.10.1
bandit==1.7.0
black==20.8b1
pylint==2.6.2
pytest-parallel==0.1.0
pytest-repeat==0.9.1
dependency-check==0.5.0
endef
export HERE_TESTS_REQUIREMENTS


# -- this target will produce the test requirements for python
prepare-test: $(TESTS_REQUIREMENTS) $(BUILD_REQUIREMENTS) $(VIRTUAL_ENV)
$(TESTS_REQUIREMENTS):
	@echo "[python] :: creating requirements for test"
	@echo "$$HERE_TESTS_REQUIREMENTS" > $@
	@echo "[python] :: test requirements creation DONE."

# BEWARE: hack using a trap to ensure the virtual env directory will be remove
# if the installation process fails
$(VIRTUAL_ENV): $(TESTS_REQUIREMENTS) $(BUILD_REQUIREMENTS)
	@echo "[python] :: creating the virtual environment"
	@set -euo pipefail; \
	function remove_me() { if (( $$? != 0 )); then rm -fr $@; fi; }; \
	trap remove_me EXIT; \
	if [ -d $(PYTHON_SRC) ]; then \
		rm -rf $@; \
		$(PYTHON_BIN) -m venv $@ && \
		source $@/bin/activate && \
		pip install -r $(TESTS_REQUIREMENTS) && \
		if [ -f $(BUILD_REQUIREMENTS) ]; then \
			pip install -r $(BUILD_REQUIREMENTS); \
		fi; \
	fi;
	@echo "[python] :: virtual environment creation DONE."

# -- this target will trigger the tests
test: $(VIRTUAL_ENV) $(SRC_FILES) $(TEST_FILES)
	@echo "[$@] :: checking requirements module $(MODULE_NAME)"
	@set -euo pipefail; \
	if test -f $(BUILD_REQUIREMENTS) && \
		cat $(BUILD_REQUIREMENTS) | \
		sed -E -e 's/#.*//' -e 's/ +$$//' -e '/^$$/d' | \
		grep -vqE '[<=>]='; \
	then \
		echo '[$@] :: at least one dependency has a version not specified.' && exit 1; \
	fi;
	@echo "[$@] :: Testing module $(MODULE_NAME)"
	@set -euo pipefail; \
	if [ -d $(VIRTUAL_ENV) ] && [ -d $(PYTHON_SRC) ]; \
	then \
		source $(VIRTUAL_ENV)/bin/activate && \
		pylint --reports=n --rcfile=$(PYLINTRC_LOCATION) $(PYTHON_SRC)/*; \
		black --check $(PYTHON_SRC); \
		bandit -r -x '*_test.py' -f screen $(PYTHON_SRC); \
		[ -f $(TEST_ENV) ] && \
		PROJECT=$(PROJECT) PROJECT_ENV=$(PROJECT_ENV) APP_NAME=$(MODULE_NAME) \
			DB_HOST=localhost source ./$(TEST_ENV); \
		PROJECT=$(PROJECT) PROJECT_ENV=$(PROJECT_ENV) \
		APP_NAME=$(MODULE_NAME) DB_HOST=localhost \
		$(PYTHON_BIN) -m pytest -vv \
			--cov $(PYTHON_SRC) \
			--cov-config=$(COVERAGERC_LOCATION) \
			--cov-report term-missing \
			--cov-fail-under 100 \
			$(PYTHON_SRC); \
	fi;
	@echo "[$@] :: Testing DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Building > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcr)

BUILD_REVISION = revision
GCR_DEPENDENCIES := $(BUILD_REQUIREMENTS) $(SRC_FILES) Dockerfile $(wildcard run.sh)


# -- target triggering the build of a Cloud Run docker image
# HACK: second call is there to generate the revision file so it contains the sha
# of the generated image
build-app: $(BUILD_REVISION)
$(BUILD_REVISION): $(GCR_DEPENDENCIES)
	@echo "[$@] :: building the GCR image for module $(MODULE_NAME)"
	@docker build \
        --tag gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
        --build-arg PROJECT=$(PROJECT) \
        --build-arg PROJECT_ENV=$(PROJECT_ENV) \
        .
	@echo "[$@] :: generating intermediary file"
	@docker build \
		--quiet \
        --tag gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
        --build-arg PROJECT=$(PROJECT) \
        --build-arg PROJECT_ENV=$(PROJECT_ENV) \
        . > $(BUILD_REVISION)
	@echo "[$@] :: GCR image for module $(MODULE_NAME) built."

clean-app:
	@rm -fr $(VIRTUAL_ENV) $(TESTS_REQUIREMENTS) $(BUILD_REVISION)

# -- invalid TYPE value
else
build-app:
	@echo "[$@] :: Invalid build parameter TYPE='$(TYPE)'"
	@exit 1

endif # build-app definition


build: test build-app


# ---------------------------------------------------------------------------------------- #
# -- < Local Testing > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcr)

LOCAL_TEST_GCR ?= gunicorn -b :8080 -t 900 -w 3 --reload main:app
RUN_PORT       ?= 8080

# -- target to locally run a GCR application from its docker container
local-test:
	@echo "[$@] :: running the local GCR $(MODULE_NAME)"
	@touch /tmp/env_$(PROJECT)
	@if [ -f $(TEST_ENV) ]; then \
		sed 's/^export //' $(TEST_ENV) \
		| sed 's/\$$PROJECT_ENV/$(PROJECT_ENV)/g' \
		| sed 's/\$$PROJECT/$(PROJECT)/g' \
		 > /tmp/env_$(PROJECT); \
	fi;
	@if [ -f creds.json ]; then \
		echo 'GOOGLE_APPLICATION_CREDENTIALS=/creds/creds.json' >> /tmp/env_$(PROJECT); \
	fi;
	docker run -it \
		-v $(shell pwd):/creds \
		-v $(shell pwd)/$(PYTHON_SRC):/app \
		-e APP_NAME=$(MODULE_NAME) \
		-e PROJECT_ENV=$(PROJECT_ENV) \
		-e PROJECT_NAME=$(PROJECT) \
		-e DB_HOST=$(SANDBOX_DB_HOST) \
		-e GUNICORN_DEBUG=1 \
		--env-file /tmp/env_$(PROJECT) \
		-p $(RUN_PORT):8080 \
		-t gcr.io/$(PROJECT)/$(MODULE_NAME):latest \
		$(LOCAL_TEST_GCR)

else
local-test:
	@echo "[$@] :: Invalid parameter TYPE='$(TYPE)'"
	@exit 1

endif # local-test definition


# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
TF_INIT  = iac/.terraform/terraform.tfstate
TF_VARS  = iac/terraform.tfvars
TF_PLAN  = iac/tfplan
TF_ENV   = iac/env.json
TF_STATE = $(wildcard iac/*.tfstate iac/.terraform/*.tfstate)
TF_FILES = $(shell [ -d iac ] && find ./iac -type f -name "*.tf")


# -- internal definition for easing changes
# TODO rename the app_name to module_name: will require refactor of all tf files.

define HERE_TF_VARS
app_name          = "$(APP_NAME)"
module_name       = "$(MODULE_NAME)"
project           = "$(PROJECT)"
project_env       = "$(PROJECT_ENV)"
deploy_bucket     = "$(DEPLOY_BUCKET)"
env_file          = "env.json"
endef
export HERE_TF_VARS

# -- this target will initialize the terraform initialization
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
				-backend-config=prefix=terraform-state/$(MODULE_NAME) \
				-input=false; \
		else \
			echo "[iac-init] :: terraform already initialized"; \
		fi; \
	fi;


# -- this target will create the terraform.tfvars file
iac-prepare: $(TF_VARS) $(TF_ENV) # provided for convenience
$(TF_ENV): $(ENV_FILE)
	@echo "[iac-prepare] :: copy $(TF_ENV) file";
	@cp "$(ENV_FILE)" "$(TF_ENV)"
	@echo "[iac-prepare] :: copy $(TF_ENV) file DONE.";
$(TF_VARS): $(BUILD_REVISION) $(TF_INIT)
	@if [ -d iac ]; then \
		echo "[iac-prepare] :: generation of $(TF_VARS) file"; \
		echo "$$HERE_TF_VARS" > $(TF_VARS); \
		case "$(TYPE)" in \
			"gcr") \
				echo 'revision = "$(shell \
					gcloud container images list-tags gcr.io/$(PROJECT)/$(MODULE_NAME) \
					--quiet --filter tags=latest --format="get(digest)")"' \
				>> $(TF_VARS); \
				echo 'cloudrun_url_suffix = "$(shell \
					gsutil cat gs://$(DEPLOY_BUCKET)/cloudrun-url-suffix/$(REGION))"' \
				>> $(TF_VARS); \
				;;\
			"gcf" | "gae") \
				HASH=$$( \
					gsutil -m cat gs://$(DEPLOY_BUCKET)/terraform-state/$(MODULE_NAME)/hash); \
				echo 'revision = "'$${HASH}'"' >> $(TF_VARS); \
				;; \
		esac; \
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
$(TF_PLAN): $(TF_VARS) $(TF_ENV) $(TF_FILES)
	@set -euo pipefail; \
	if [ -d iac ]; then \
		echo "[iac-plan] :: planning the iac for module $(MODULE_NAME)"; \
		cd iac && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN)); \
		echo "[iac-plan] :: planning the iac for module $(MODULE_NAME) DONE."; \
	else \
		echo "[iac-plan] :: no infrastructure"; \
	fi;


# -- this target will only trigger the iac of the designated module
iac-deploy: $(TF_PLAN)
	@echo "[$@] :: applying iac for module $(MODULE_NAME)"
	@if [ -d iac ]; then \
		cd iac; \
		terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN)); \
	else \
		echo "[$@] :: no infrastructure"; \
	fi;
	@echo "[$@] :: is finished on module $(MODULE_NAME)"

# -- this target will clean the intermediary iac files
# might need to delete the iac/.terraform/terraform.tfstate file
iac-clean:
	@echo "[$@] :: cleaning Iac intermediary files : '$(TF_PLAN), $(TF_VARS)'"
	@if [ -d iac ]; then \
		rm -fr $(TF_PLAN) $(TF_VARS) $(TF_ENV) iac/.terraform; \
	fi;
	@echo "[$@] :: cleaning Iac intermediary files DONE."


# ---------------------------------------------------------------------------------------- #
# -- < Deploying > --
# ---------------------------------------------------------------------------------------- #
ifeq ($(TYPE), gcr)
deploy-app:
	@echo "[$@] :: pushing docker image."
	@docker push gcr.io/$(PROJECT)/$(MODULE_NAME):latest;
	@echo "[$@] :: docker push is over."

.PHONY: deploy-apigee
deploy-apigee:
	@echo "Deploy to APIGEE"
	$(SHELL) ../../bin/deploy-apigee;

else
deploy-app:
	@echo "[$@] :: Invalid parameter TYPE='$(TYPE)'"
	@exit 1

deploy-apigee:
	@echo "[$@] :: Invalid parameter TYPE='$(TYPE)'"
	@exit 1

endif  # deploy-app definition

deploy: deploy-app iac-plan-clean iac-deploy deploy-apigee


# ---------------------------------------------------------------------------------------- #
# -- < Include Custom makefile > --
# ---------------------------------------------------------------------------------------- #
-include custom.mk
