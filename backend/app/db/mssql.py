"""MSSQL database connection (financial data: orders, payments)."""
from __future__ import annotations

import logging

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

logger = logging.getLogger(__name__)


class MSSQLBase(DeclarativeBase):
    """Base class for MSSQL ORM models."""

    pass


mssql_engine = create_engine(
    settings.mssql_database_uri,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=10,
    max_overflow=20,
    future=True,
    echo=False,
    # MSSQL pyodbc specific: faster executemany
    fast_executemany=True,
)

MSSQLSessionLocal = sessionmaker(
    bind=mssql_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=Session,
)


def get_mssql_db() -> Session:
    """
    FastAPI dependency that yields an MSSQL session and ensures it closes.

    Usage:
        @router.get("/")
        def handler(db: Session = Depends(get_mssql_db)):
            ...
    """
    db = MSSQLSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_mssql_connection() -> bool:
    """Return True if MSSQL is reachable."""
    try:
        with mssql_engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("MSSQL connection failed: %s", exc)
        return False
