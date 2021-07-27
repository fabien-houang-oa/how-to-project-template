"""Default module for hello world purpose."""


import base64
import json

from flask import jsonify, request

from wrappers.blueprint_factory import make_blueprint


class DefaultError(Exception):
    """Error while building."""


@make_blueprint("default")
def build(blueprint):
    """Build the endpoint. The first argument is always the blueprint integration."""

    @blueprint.route("/simple", methods=["GET", "POST"])
    def _internal():  # pylint: disable=unused-variable
        """Define Internal method."""
        authorization = request.headers.get(
            "X-Forwarded-Authorization", request.headers["Authorization"]
        )
        caller_info = json.loads(
            base64.b64decode(authorization[7:].split(".")[1] + "===")
        )
        who = request.args.get("who", caller_info["email"])
        return jsonify(
            {
                "result": f"Hello {who}",
                "caller_info": caller_info,
                "headers": dict(request.headers),
            }
        )
