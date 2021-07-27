"""service.py UT."""


from default_api.service import DefaultService


def test_simple():
    """test simple."""
    srv = DefaultService()
    assert srv.upper("toto") == "TOTO"
