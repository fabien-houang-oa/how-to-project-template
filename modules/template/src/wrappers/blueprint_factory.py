"""Blue print factory for convenience and CORS integration."""


import logging
from typing import Optional, List, Tuple

from flask import Blueprint, jsonify
from flask_cors import CORS
from flask_restx import Api

from google.cloud import error_reporting

from helpers import exceptions


LOGGER = logging.getLogger(__name__)
DEFAULT_CORS_METHOD = ["GET", "HEAD", "POST", "OPTIONS", "PUT", "PATCH", "DELETE"]


def make_blueprint(
    name: str,
    url_prefix: Optional[str] = None,  # pylint: disable=unsubscriptable-object
    cors_origins: str = "*",
    cors_methods: Optional[List[str]] = None,  # pylint: disable=unsubscriptable-object
) -> Blueprint:  # pragma: no cover
    """Make the CORS integration for Flask Blueprint.

    Args:
        name: Name of the blueprint
        url_prefix: Url prefix above the defined url of the blueprint
        cors_origins: List of the tolerated origins (default is all).
        cors_methods: List of the supported HTTP methods (default is all).

    Returns:
        the function wrapped
    """
    if cors_methods is None:
        cors_methods = DEFAULT_CORS_METHOD

    def _internal(function):
        """Create blueprint, set up CORS and optional url prefix."""
        blueprint = Blueprint(name, name)

        # add configured url_prefix for this blueprint
        setattr(blueprint, "external_url_prefix", url_prefix)

        # add CORS protection
        CORS(
            blueprint,
            # CORS control: all by default
            origins=cors_origins,
            methods=cors_methods,
        )

        def _wrapped_function(*args, **kwargs):
            """Call real function and ensure blueprint is returned."""
            function(blueprint, *args, **kwargs)
            return blueprint

        return _wrapped_function

    return _internal


def make_api(
    api_name: str,
    api_version: str,
    api_version_path: str,
    api_title: str,
    api_description: str,
    error_reporting_client: error_reporting.Client,
) -> Tuple[Blueprint, Api]:  # pragma: no cover
    """Create a blueprint API.

    The arguments are linked to flask_restx.Api

    Args:
        api_version: The API version
        api_version_path: The API version PATH
        api_title: Title of the API
        api_description: Long description of the API
        error_reporting_client: Error Reporting client

    Returns:
        tuple of blueprint linked to the API and the API itself
    """

    @make_blueprint(f"{api_name}_{api_version_path}", url_prefix=f"/{api_version_path}")
    def build(blueprint: Blueprint):  # pylint: disable=unused-variable
        """
        Build the default test endpoint.

        Args:
            blueprint: Blueprint for flask routing integration

        Returns:
            None
        """
        api = Api(
            blueprint, version=api_version, title=api_title, description=api_description
        )
        setattr(blueprint, "api", api)

        for exception_name in exceptions.__all__:
            exception_cls = getattr(exceptions, exception_name)

            @api.errorhandler(exception_cls)
            def handle_bad_request(error):  # pylint: disable=unused-variable
                """Handle the exception code according to http error code."""
                LOGGER.error(str(error))
                # pylint: disable=cell-var-from-loop
                if 500 <= error.HTTP_ERROR_CODE <= 599:
                    error_reporting_client.report_exception()

                # pylint: disable=cell-var-from-loop
                return jsonify({"error": str(error)}), error.HTTP_ERROR_CODE

        @api.errorhandler(Exception)
        def handle_broad_exception(error):  # pylint: disable=unused-variable
            """Handle a broad exception if none of the previous handlers did it ."""
            LOGGER.error(str(error))
            error_reporting_client.report_exception()

            return jsonify({"error": str(error)}), 500

        return blueprint

    blueprint = build()  # pylint: disable=no-value-for-parameter

    return blueprint, blueprint.api
