"""Common exceptions for all config_api entities."""


from helpers.base_exceptions import ApiBaseUserException, ApiBaseInternalErrorException


__all__ = [
    "BadRequest",
    "PermissionDenied",
    "InternalError",
    "InternalProviderError",
    "InternalStateError",
]


class BadRequest(ApiBaseUserException):  # pragma: no cover
    """Class signaling a bad request."""

    HTTP_ERROR_CODE = 400


class PermissionDenied(ApiBaseUserException):  # pragma: no cover
    """Class signaling that the user is not allowed to do the action."""

    HTTP_ERROR_CODE = 403


class InternalError(ApiBaseInternalErrorException):  # pragma: no cover
    """Class signaling an internal error."""

    def __init__(self, *args, **kwargs):  # pragma: no cover
        """Build the exception."""
        default_message = "Internal error"

        if args or kwargs:
            super().__init__(*args, **kwargs)
        else:
            super().__init__(default_message)


class InternalProviderError(InternalError):  # pragma: no cover
    """Class signaling the an error occurred in the provider layer."""


class InternalStateError(InternalError):  # pragma: no cover
    """Class signaling that the application is in inconsistent state."""
