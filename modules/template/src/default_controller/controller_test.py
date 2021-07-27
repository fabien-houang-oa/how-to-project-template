"""default UAT."""


import datetime
import imp
import json
from unittest.mock import MagicMock, patch

import pytest

import wrappers.blueprint_factory  # pylint: disable=unused-import
import default_controller.controller


DEFAULT_DATETIME = datetime.datetime(2020, 12, 11, 9, 8, 7)


### FIXTURES ###


@pytest.fixture(autouse=True)
def mock_blueprint():
    """Mock blue print by mocking the decorator and reloding the module."""

    class MockBlueprint:
        """Mock Blueprint with route method."""

        def __init__(self, *args, **kwargs):  # pylint: disable=unused-argument
            self.map = {}

        def route(self, *args, **kwargs):  # pylint: disable=unused-argument
            """Mock route method."""

            def _internal(function):
                self.map[args[0]] = function
                return function

            return _internal

        def call(self, uri):
            """Call uri to simulate blueprint."""
            return self.map[uri]()

    mock_blueprints = MockBlueprint()

    def mock_bp_fact(function):
        """Mock make_blueprint factory."""

        def _internal(*args, **kwargs):
            function(mock_blueprints, *args, **kwargs)
            return mock_blueprints

        return _internal

    patch(
        "wrappers.blueprint_factory.make_blueprint", return_value=mock_bp_fact
    ).start()
    imp.reload(default_controller.controller)
    patch("default_controller.controller.jsonify", side_effect=json.dumps).start()


### TESTS ###


@pytest.fixture
def mock_valid_request():
    """Mock an invalid request."""
    mck = patch("default_controller.controller.request", new=MagicMock()).start()
    mck.get_json.return_value = "truc"
    mck.headers = {
        "X-Forwarded-Authorization": (
            "eyJhbGciOiJSUzI1NiIsImtpZCI6IjY5ZWQ1N2Y0MjQ0OTEyODJhMTgwMjBmZDU4NTk1NGI3MG"
            "JiNDVhZTAiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb"
            "20iLCJhenAiOiIzMjU1NTk0MDU1OS5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsImF1ZCI"
            "6IjMyNTU1OTQwNTU5LmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTA2NTk0N"
            "TUyNDk2MDE5ODA2MTIyIiwiaGQiOiJsb3JlYWwuY29tIiwiZW1haWwiOiJzZWJhc3RpZW4ubW9"
            "yYW5kQGxvcmVhbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6InFLUUF1O"
            "FdaakVMelpaQUVrdExIemciLCJpYXQiOjE2MjA3NjgyMzksImV4cCI6MTYyMDc3MTgzOX0.FTs"
            "cL8H8mFM6U0a0phkuPrYBG-mV2iyIBe_8mqbcRINAjawwKZhlxxMj1dXqgGU4hSFWbPlEk1_Gg"
            "9J2sprh4LFCkBtCxVMmhQJBR4DNK7qVsMrkUeEGKQ8Q7DYeSNMGy2QvKkhvk4f5wuP_Mag1qho"
            "dkaxyb7Vsqzh_Z7VXTqjAJUWNWAlwIxrahe59wMGH2L4Q7RftZ9noR8RdwE5fJf7kVMw1oz7Uc"
            "7Wv9EKUU35qm-sOOsO4pavlgeabEJ8UJMGFH_qPI0Zin18dPwqewObNH2hTXjEwUaebF9fDhcN"
            "c_nCeiMkhYymAGJg_ddM7_3-dWJryMCM2kTHlkGjAmQ"
        ),
        "Authorization": "bbbb",
    }


def test_valid_message(
    mock_valid_request,
):  # pylint: disable=redefined-outer-name,unused-argument
    """Test invalid request payload."""
    default_controller.controller.build().call(  # pylint: disable=no-value-for-parameter
        "/simple"
    )
