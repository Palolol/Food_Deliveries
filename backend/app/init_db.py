"""Database initialization script.

Creates all tables in MSSQL (single database).

Usage:
    cd backend
    python -m app.init_db
"""
from __future__ import annotations

import logging

from app.db.mssql import MSSQLBase, mssql_engine

# Import ALL models so their tables register on the shared metadata
import app.models.mssql  # noqa: F401

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(name)s | %(message)s")
logger = logging.getLogger("init_db")


def init_mssql() -> None:
    logger.info("Creating all MSSQL tables...")
    MSSQLBase.metadata.create_all(bind=mssql_engine)
    logger.info("MSSQL tables ready.")


if __name__ == "__main__":
    init_mssql()
    logger.info("Database initialization complete.")
