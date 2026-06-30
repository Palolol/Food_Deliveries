"""MySQL module removed — everything migrated to MSSQL.

This file is kept as a compatibility shim so any remaining import of
`get_mysql_db` or `MySQLBase` is re-directed to the MSSQL equivalents
without breaking imports during the transition.
"""
from app.db.mssql import MSSQLBase as MySQLBase  # noqa: F401
from app.db.mssql import get_mssql_db as get_mysql_db  # noqa: F401
from app.db.mssql import mssql_engine as mysql_engine  # noqa: F401


def test_mysql_connection() -> bool:
    """Alias for MSSQL connection test (MySQL removed)."""
    from app.db.mssql import test_mssql_connection
    return test_mssql_connection()
