"""MySQL database connection (application data)."""
from __future__ import annotations

import logging

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

logger = logging.getLogger(__name__)


class MySQLBase(DeclarativeBase):
    """Base class for MySQL ORM models."""

    pass


# pool_pre_ping handles dropped connections gracefully
mysql_engine = create_engine(
    settings.mysql_database_uri,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=10,
    max_overflow=20,
    future=True,
    echo=False,
)

MySQLSessionLocal = sessionmaker(
    bind=mysql_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=Session,
)


def get_mysql_db() -> Session:
    """
    FastAPI dependency that yields a MySQL session and ensures it closes.

    Usage:
        @router.get("/")
        def handler(db: Session = Depends(get_mysql_db)):
            ...
    """
    db = MySQLSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_mysql_connection() -> bool:
    """Return True if MySQL is reachable."""
    try:
        with mysql_engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("MySQL connection failed: %s", exc)
        return False
