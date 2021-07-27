"""Secret manager helper."""


import logging


class SecretManager:
    """Secret retriever."""

    def __init__(self, secret_manager_service):  # pragma: no cover
        """Initialize SecretManager object."""
        self.secret_manager_service = secret_manager_service

    def load(
        self, project: str, secret: str, version: str = "latest"
    ):  # pragma: no cover
        """Load a secret from project.

        Arguments:
            project -- project where the secret is kept
            secret -- name of the secret
            version -- version of the secret to load. By defalt the latest

        Returns:
            The decoded content
        """
        secret_uri = "projects/{}/secrets/{}/versions/{}".format(
            project, secret, version
        )
        logging.info("Reading secret %s", secret_uri)
        return (
            self.secret_manager_service.access_secret_version(name=secret_uri)
            .payload.data.decode("utf-8")
            .strip()
        )
