"""User application making up."""


import logging
from typing import List

import flask
from google.cloud import error_reporting

# import managers & controllers
from default_api import controller as default_controller_api
from default_api.service import DefaultService
import default_controller.controller
from helpers import constants
from wrappers.blueprint_factory import make_api

LOGGER = logging.getLogger(__name__)


def make_app() -> List[flask.Blueprint]:  # pragma: no cover
    """Set up API blueprint, controllers, services, providers and ORM.

    Returns:
        The API configured blueprint.
    """
    LOGGER.info("Creating API blueprint.")

    ### Build the main controllers ###
    blue_prints = list()

    ### Build the standard blueprints ###
    blue_prints.append(
        default_controller.controller.build()  # pylint: disable=no-value-for-parameter
    )

    ### Build APIs
    blue_print_api, api = make_api(
        api_name=constants.API_NAME,
        api_version=constants.API_VERSION,
        api_version_path=constants.API_VERSION_PATH,
        api_title=constants.API_TITLE,
        api_description=constants.API_DESCRIPTION,
        error_reporting_client=error_reporting.Client(),
    )
    blue_prints.append(blue_print_api)

    # Instantiate services
    default_service = DefaultService()

    # Instantiate controllers
    default_controller_api.build(api, default_service)

    return blue_prints
