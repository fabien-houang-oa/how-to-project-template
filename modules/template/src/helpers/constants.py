"""Generic constants."""

import os
import re

import requests

# pylint: disable=fixme


# Load PROJECT env variable
PROJECT = os.environ.get(
    "PROJECT", os.environ.get("PROJECT_NAME", os.environ.get("GCP_PROJECT", None))
)
if PROJECT is None:  # pragma: no cover
    # fetch project from metadata server
    PROJECT = requests.get(
        "http://metadata.google.internal/computeMetadata/v1/project/project-id",
        headers={"Metadata-Flavor": "Google"},
    ).text

# Load PROJECT_ENV env variable
PROJECT_ENV = os.environ.get("PROJECT_ENV", None)
if PROJECT_ENV is None:  # pragma: no cover
    # try to fetch from PROJECT NAME
    PROJECT_ENV = re.compile(r".*-(dv|qa|pd|np)$").match(PROJECT)
    if PROJECT_ENV:
        PROJECT_ENV = PROJECT_ENV.groups()[0]
    else:
        # fallback to sandbox
        PROJECT_ENV = "sbx"

# global application name
APP_NAME = os.environ["APP_NAME"]
APP_NAME_SHORT = os.environ.get("APP_NAME", None)
if APP_NAME_SHORT is None:  # pragma: no cover
    APP_NAME_SHORT = APP_NAME.replace("-", "")

# TODO change the followings value to match your api domain
# API information
API_NAME = "btdp"
API_VERSION = "1.0"
API_VERSION_PATH = "v1"
API_TITLE = "BTDP <Domain> Interface API"
API_DESCRIPTION = "The BTDP <Domain> of flows and services API."
