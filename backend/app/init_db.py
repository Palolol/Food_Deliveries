"""Database initialization script.

Run once to create tables on both MySQL and MSSQL.

Usage:
    cd backend
    python -m app.init_db
"""
from __future__ import annotations

import logging

from app.db.mssql import MSSQLBase, mssql_engine
from app.db.mysql import MySQLBase, mysql_engine

# Import models so their tables register on the metadata
import app.models.mysql  # noqa: F401
import app.models.mssql  # noqa: F401

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(name)s | %(message)s")
logger = logging.getLogger("init_db")


def init_mysql() -> None:
    logger.info("Creating MySQL tables...")
    MySQLBase.metadata.create_all(bind=mysql_engine)
    logger.info("MySQL tables ready")


def init_mssql() -> None:
    logger.info("Creating MSSQL tables...")
    MSSQLBase.metadata.create_all(bind=mssql_engine)
    logger.info("MSSQL tables ready")


if __name__ == "__main__":
    init_mysql()
    init_mssql()
    logger.info("All databases initialized.")
