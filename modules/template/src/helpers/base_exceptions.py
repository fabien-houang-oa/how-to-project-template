"""Base for API recognized exceptions."""


class ApiBaseException(Exception):  # pragma: no cover
    """Base exception for config api."""


class ApiBaseUserException(ApiBaseException):  # pragma: no cover
    """Base exception for user error config api."""

    HTTP_ERROR_CODE = 400


class ApiBaseInternalErrorException(ApiBaseException):  # pragma: no cover
    """Base exception for internal error config api."""

    HTTP_ERROR_CODE = 500
