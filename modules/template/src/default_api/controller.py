"""Groups Extractor API."""


import logging

from flask import jsonify, request
from flask_restx import Api, fields, Resource

from default_api.service import DefaultService


LOGGER = logging.getLogger(__name__)


def build(api: Api, service: DefaultService) -> None:
    """Build API."""
    LOGGER.debug("Create %s controller", __name__)

    namespace = api.namespace(
        "Groups Extractor",
        path="/testapi",
        description="Endpoint to test an API",
    )

    model = namespace.model(
        "TestApiModel",
        {
            "who": fields.List(
                fields.String,
                required=True,
                description="List of service account email",
            ),
        },
    )

    @namespace.route("")
    class HelloWorldResource(Resource):  # pylint: disable=unused-variable
        """Resource for listing the Cloud Identity group(s) members."""

        @namespace.doc(description="Say hello to world.")
        def get(self):
            """Say hello world."""
            LOGGER.debug("controller.get: hello world")

            people = service.upper("World")

            return jsonify({"message": f"Hello {people}!"})

        @namespace.doc(description="Say hello to someone")
        @namespace.expect(model)
        def post(self):
            """Add the designated members in the firestore collection of \
            allowed service accounts to extract group."""
            LOGGER.debug("controller.post: say hello to someone")

            people = service.upper(request.json["who"])

            return jsonify({"message": f"Hello {people}!"})

    @namespace.doc(description="Say hello to someone.")
    @namespace.route("/<string:who>")
    class HelloWhoResource(Resource):  # pylint: disable=unused-variable
        """Resource for checking the userid is part of Cloud Identity group."""

        @namespace.doc(
            description="Checking the userid is in Cloud Identity group",
            params={"who": "The Perso to say hello."},
        )
        def get(self, who: str):
            """Say hello to someone."""
            LOGGER.debug("controller.get: hello %r", who)

            people = service.upper(who)

            return jsonify({"message": f"Hello {people}!"})
