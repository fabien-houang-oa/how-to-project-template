"""Group Extractor AUT."""

import json
from unittest.mock import MagicMock

from flask import Blueprint
from flask import Flask
from flask_restx import Api
import pytest

from default_api import controller


# -------------------------------------------------------------------------------------
# --- < Generic fixtures > ---
# -------------------------------------------------------------------------------------


@pytest.fixture(name="app")
def app_fixture():
    """Set up testing Flask app."""
    flask_app = Flask(__name__)
    flask_app.testing = True
    flask_app.config["ERROR_404_HELP"] = False

    yield flask_app


@pytest.fixture(name="api")
def api_fixture(app):
    """Set up api and blueprint."""
    blueprint = Blueprint("btdp_api", __name__)
    api = Api(blueprint)

    app.register_blueprint(blueprint)
    yield api


# -------------------------------------------------------------------------------------
# --- < Fixtures > ---
# -------------------------------------------------------------------------------------
@pytest.fixture(name="service")
def service_fixture():
    """Set up service fixture."""
    mck_service = MagicMock()
    mck_service.upper = lambda x: x.upper()
    yield mck_service


# -------------------------------------------------------------------------------------
# --- < Tests for GET (list) > ---
# -------------------------------------------------------------------------------------
def test_get(app, api, service):  # pylint: disable=invalid-name
    """Test that the returned members list is not empty."""
    controller.build(api, service)

    with app.test_client() as client:
        response = client.get("/testapi")
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type", type=str) == "application/json"

        assert json.loads(response.data) == {"message": "Hello WORLD!"}


# -------------------------------------------------------------------------------------
# --- < Tests for POST (list) > ---
# -------------------------------------------------------------------------------------
def test_post(app, api, service):  # pylint: disable=invalid-name
    """Test that the returned members list is not empty."""
    controller.build(api, service)

    with app.test_client() as client:
        response = client.post("/testapi", json={"who": "seb"})
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type", type=str) == "application/json"

        assert json.loads(response.data) == {"message": "Hello SEB!"}


# -------------------------------------------------------------------------------------
# --- < Tests for GET (resource) > ---
# -------------------------------------------------------------------------------------
def test_get_res(app, api, service):  # pylint: disable=invalid-name
    """Test that the returned members list is not empty."""
    controller.build(api, service)

    with app.test_client() as client:
        response = client.get("/testapi/toto")
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type", type=str) == "application/json"

        assert json.loads(response.data) == {"message": "Hello TOTO!"}
