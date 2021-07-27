#!/usr/bin/env python3
"""
Main module for flask application, compatibility layer for GAE and GCR & Docker.

This file should not be modifed.
"""


import logging
import os
import warnings
from google.cloud.logging import handlers

from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix


from application import make_app  # application definition


def build_app():  # pragma: no cover
    """Build the flask app with IoC in mind."""
    # register the unique blueprint api
    flask_app = Flask(os.environ["APP_NAME"])
    flask_app.wsgi_app = ProxyFix(flask_app.wsgi_app, x_proto=1, x_host=1)
    blue_prints = make_app()
    options = {}
    for blue_print in blue_prints:
        if blue_print.external_url_prefix is not None:
            options["url_prefix"] = blue_print.external_url_prefix
        flask_app.register_blueprint(blue_print, **options)

    # set Flask app configurations
    flask_app.config["ERROR_404_HELP"] = False

    return flask_app


# prepare logs
if __name__ == "__main__" or os.environ.get("GUNICORN_DEBUG"):  # pragma: no cover
    # local
    DEFAULT_FORMAT = "[%(asctime)s] - [%(name)s] - %(levelname)s: %(message)s"
    DEFAULT_LEVEL = logging.DEBUG
    logging.basicConfig(level=DEFAULT_LEVEL, format=DEFAULT_FORMAT)

    for logger_name in (
        "google.auth.transport.requests",
        "urllib3.connectionpool",
        "urllib3.util.retry",
    ):
        logging.getLogger(logger_name).setLevel(logging.INFO)

    warnings.simplefilter("ignore")

else:
    # python3 for GAE, GAE flex, GCRun
    HANDLER = handlers.container_engine.ContainerEngineHandler()
    HANDLER.setLevel(logging.DEBUG)
    CLOUD_LOGGER = logging.getLogger()
    CLOUD_LOGGER.setLevel(logging.DEBUG)
    CLOUD_LOGGER.handlers = [HANDLER]

# Flask application, don't load in Pytest
if os.environ.get("TEST_ENV", "0") != "1":  # pragma: no cover
    app = build_app()

if __name__ == "__main__":  # pragma: no cover
    app.run(host="0.0.0.0", port=8000, debug=False)  # nosec
