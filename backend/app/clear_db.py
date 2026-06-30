"""Clear all data from the MSSQL database.

Wipes every row from every table but keeps the schema. Foreign keys use
``ondelete="CASCADE"`` on the model definitions, so deleting ``users``
cleans up everything else in one shot.

Usage:
    cd backend
    python -m app.clear_db                              # interactive confirmation
    python -m app.clear_db --yes                        # skip confirmation
    python -m app.clear_db --truncate                   # use TRUNCATE (faster)
    python -m app.clear_db --recreate                   # DROP + re-create tables

    # Preserve a specific admin user across the wipe (default: wipe all users)
    python -m app.clear_db --preserve-admin admin@example.com
    python -m app.clear_db --truncate --preserve-admin admin@example.com
    python -m app.clear_db --recreate --preserve-admin admin@example.com \\
        --new-password "newSecret123"

Refuses to run unless ``APP_ENV`` is one of: development, dev, testing, test.
"""
from __future__ import annotations

import argparse
import logging
import sys
from datetime import datetime
from typing import Iterable, Optional

from sqlalchemy import text

from app.core.config import settings
from app.db.mssql import MSSQLBase, MSSQLSessionLocal, mssql_engine
from app.models import mssql as mssql_models  # noqa: F401  (register models)
from app.services.user_service import hash_password

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(name)s | %(message)s")
logger = logging.getLogger("clear_db")

# Tables in safe delete order (children before parents).
# This is also the order used by the ``--truncate`` path.  Truncate with FK
# checks disabled tolerates any order, but we keep it consistent with the
# ORM delete path so log output matches.
TABLES_IN_ORDER: tuple[str, ...] = (
    "order_items",   # leaf
    "payments",
    "orders",
    "reviews",
    "addresses",
    "menu_items",
    "restaurants",
    "users",         # root
)

ALLOWED_ENVS = {"development", "dev", "testing", "test"}


def _confirm(prompt: str) -> bool:
    try:
        reply = input(prompt).strip().lower()
    except EOFError:
        return False
    return reply in {"y", "yes"}


def _snapshot_admin_by_email(email: str, new_password: Optional[str]) -> Optional[dict]:
    """Return a dict of fields to re-insert, or None if user not found."""
    from app.models.mssql.user import User, UserRole

    with MSSQLSessionLocal() as db:
        user = db.query(User).filter(User.email == email.lower().strip()).first()
        if not user:
            logger.error("preserve-admin: no user found with email=%r", email)
            return None
        # SQLAlchemy's Enum with native_enum=False stores the *name* of the
        # enum (e.g. "ADMIN"), not the value (e.g. "admin").  Re-insert
        # the same way it would have been stored originally.
        role_name = user.role.name if isinstance(user.role, UserRole) else str(user.role)
        snapshot = {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "phone": user.phone,
            "avatar_url": user.avatar_url,
            "password_hash": hash_password(new_password) if new_password else user.password_hash,
            "role": role_name,
            "is_active": bool(user.is_active),
        }
        logger.info("Snapshotted admin id=%s email=%s role=%s", snapshot["id"], snapshot["email"], snapshot["role"])
        return snapshot


def _reinstate_admin(snapshot: dict) -> None:
    """Re-insert the admin row at the same id via IDENTITY_INSERT."""
    with mssql_engine.begin() as conn:
        conn.execute(text("SET IDENTITY_INSERT users ON"))
        try:
            conn.execute(
                text(
                    """
                    INSERT INTO users
                        (id, email, full_name, phone, avatar_url,
                         password_hash, role, is_active, created_at, updated_at)
                    VALUES
                        (:id, :email, :full_name, :phone, :avatar_url,
                         :password_hash, :role, :is_active, :now, :now)
                    """
                ),
                {
                    "id": snapshot["id"],
                    "email": snapshot["email"],
                    "full_name": snapshot["full_name"],
                    "phone": snapshot["phone"],
                    "avatar_url": snapshot["avatar_url"],
                    "password_hash": snapshot["password_hash"],
                    "role": snapshot["role"],
                    "is_active": snapshot["is_active"],
                    "now": datetime.utcnow(),
                },
            )
        finally:
            conn.execute(text("SET IDENTITY_INSERT users OFF"))
    logger.info("Admin re-inserted id=%s email=%s", snapshot["id"], snapshot["email"])


def clear_with_orm() -> None:
    """Delete rows in dependency order using SQLAlchemy ORM so relationship
    cascades fire and FK constraints are respected.

    Order: children first, parents last. ``payments`` and ``reviews`` are
    deleted BEFORE their grandparent tables because we removed
    ``ON DELETE CASCADE`` on those FKs (they formed a multi-cascade-path
    cycle that SQL Server forbids — error 1785).
    """
    from app.models.mssql.order import Order, OrderItem
    from app.models.mssql.payment import Payment
    from app.models.mssql.review import Review
    from app.models.mssql.address import Address
    from app.models.mssql.menu import MenuItem
    from app.models.mssql.restaurant import Restaurant
    from app.models.mssql.user import User

    with MSSQLSessionLocal() as db:
        n = db.query(OrderItem).delete(synchronize_session=False)
        logger.info("Deleted %d order_item row(s)", n)
        n = db.query(Payment).delete(synchronize_session=False)
        logger.info("Deleted %d payment row(s)", n)
        n = db.query(Order).delete(synchronize_session=False)
        logger.info("Deleted %d order row(s)", n)
        n = db.query(Review).delete(synchronize_session=False)
        logger.info("Deleted %d review row(s)", n)
        n = db.query(Address).delete(synchronize_session=False)
        logger.info("Deleted %d address row(s)", n)
        n = db.query(MenuItem).delete(synchronize_session=False)
        logger.info("Deleted %d menu_item row(s)", n)
        n = db.query(Restaurant).delete(synchronize_session=False)
        logger.info("Deleted %d restaurant row(s)", n)
        n = db.query(User).delete(synchronize_session=False)
        logger.info("Deleted %d user row(s)", n)
        db.commit()
    logger.info("ORM delete complete.")


def clear_with_truncate() -> None:
    """``TRUNCATE`` every table with FKs dropped and re-added.

    Note: SQL Server's ``sp_MSforeachtable 'ALTER TABLE ? NOCHECK ...'``
    only affects ``DELETE``-time FK checks; ``TRUNCATE`` requires the FKs
    to be physically dropped.  We snapshot the FK definitions, drop them,
    truncate, then restore them so the schema is identical to before.
    """
    logger.info("Snapshotting FK definitions from sys.foreign_keys...")
    fk_snapshot: list[dict] = []
    with mssql_engine.connect() as conn:
        fk_rows = conn.execute(
            text(
                """
                SELECT fk.name AS fk_name,
                       OBJECT_NAME(fk.parent_object_id) AS tbl,
                       OBJECT_NAME(fk.referenced_object_id) AS ref_tbl
                FROM sys.foreign_keys fk
                """
            )
        ).fetchall()

        for fk_name, tbl, ref_tbl in fk_rows:
            col_rows = conn.execute(
                text(
                    """
                    SELECT COL_NAME(fkc.parent_object_id, fkc.parent_column_id),
                           COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)
                    FROM sys.foreign_key_columns fkc
                    WHERE fkc.constraint_object_id = OBJECT_ID(:name)
                    ORDER BY fkc.constraint_column_id
                    """
                ),
                {"name": fk_name},
            ).fetchall()
            # Get the on_delete action for this FK
            action_row = conn.execute(
                text(
                    """
                    SELECT fk.delete_referential_action_desc
                    FROM sys.foreign_keys fk
                    WHERE fk.name = :name
                    """
                ),
                {"name": fk_name},
            ).first()
            on_delete = action_row[0] if action_row else "NO_ACTION"

            fk_snapshot.append(
                {
                    "fk_name": fk_name,
                    "tbl": tbl,
                    "ref_tbl": ref_tbl,
                    "src_cols": [c[0] for c in col_rows],
                    "ref_cols": [c[1] for c in col_rows],
                    "on_delete": on_delete,
                }
            )

    logger.info("Dropping %d FK constraint(s)...", len(fk_snapshot))
    with mssql_engine.begin() as conn:
        for fk in fk_snapshot:
            conn.execute(text(f"ALTER TABLE [{fk['tbl']}] DROP CONSTRAINT [{fk['fk_name']}]"))
        for table in TABLES_IN_ORDER:
            logger.info("TRUNCATE %s", table)
            conn.execute(text(f"TRUNCATE TABLE {table}"))
        # Re-add FKs. Map SQL Server action names back to keywords.
        action_map = {
            "NO_ACTION": "NO ACTION",
            "CASCADE": "CASCADE",
            "SET_NULL": "SET NULL",
            "SET_DEFAULT": "SET DEFAULT",
        }
        for fk in fk_snapshot:
            on_del = action_map.get(fk["on_delete"], "NO ACTION")
            src = ", ".join(f"[{c}]" for c in fk["src_cols"])
            ref = ", ".join(f"[{c}]" for c in fk["ref_cols"])
            ddl = (
                f"ALTER TABLE [{fk['tbl']}] ADD CONSTRAINT [{fk['fk_name']}] "
                f"FOREIGN KEY ({src}) REFERENCES [{fk['ref_tbl']}] ({ref}) "
                f"ON DELETE {on_del}"
            )
            logger.info("Restoring FK %s", fk["fk_name"])
            conn.execute(text(ddl))
    logger.info("TRUNCATE complete (FKs re-added).")


def recreate_all() -> None:
    """DROP every table, then re-create from current models."""
    logger.warning("Dropping ALL tables...")
    MSSQLBase.metadata.drop_all(bind=mssql_engine)
    logger.info("Recreating tables from models...")
    MSSQLBase.metadata.create_all(bind=mssql_engine)
    logger.info("Recreate complete.")


def show_table_counts() -> None:
    """Print row counts for every table — useful before/after the wipe."""
    with mssql_engine.connect() as conn:
        for table in TABLES_IN_ORDER:
            row = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
            logger.info("  %-15s %s", table, row)


def _check_env() -> None:
    env = (settings.app_env or "").lower()
    if env not in ALLOWED_ENVS:
        logger.error(
            "Refusing to run: APP_ENV=%r is not in %s. "
            "Set APP_ENV=development in your .env to enable this script.",
            env,
            sorted(ALLOWED_ENVS),
        )
        sys.exit(2)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Wipe all data from MSSQL database.")
    parser.add_argument("--yes", action="store_true", help="Skip the confirmation prompt.")
    parser.add_argument(
        "--truncate",
        action="store_true",
        help="Use TRUNCATE (faster, resets identity). Default is ORM delete.",
    )
    parser.add_argument(
        "--recreate",
        action="store_true",
        help="DROP every table and re-create from models (nuclear option).",
    )
    parser.add_argument(
        "--preserve-admin",
        metavar="EMAIL",
        help=(
            "Re-insert this user row after the wipe (keeping the same id, role, "
            "and password hash). Use this to avoid locking yourself out."
        ),
    )
    parser.add_argument(
        "--new-password",
        metavar="PASSWORD",
        help="If --preserve-admin is set, reset the admin's password to this value.",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)

    _check_env()

    logger.info("Target database: %s", settings.mssql_database_uri.split("@")[-1])
    logger.info("Row counts BEFORE:")
    show_table_counts()

    snapshot: Optional[dict] = None
    if args.preserve_admin:
        snapshot = _snapshot_admin_by_email(args.preserve_admin, args.new_password)
        if snapshot is None:
            return 1

    if not args.yes:
        msg = (
            "This will DELETE ALL ROWS"
            + (" and DROP+RECREATE tables" if args.recreate else "")
            + (f" (preserving admin {args.preserve_admin})" if snapshot else "")
            + ". Continue? [y/N] "
        )
        if not _confirm(msg):
            logger.info("Aborted by user.")
            return 1

    try:
        if args.recreate:
            recreate_all()
        elif args.truncate:
            clear_with_truncate()
        else:
            clear_with_orm()
    except Exception as exc:  # noqa: BLE001
        logger.exception("Clear failed: %s", exc)
        return 1

    if snapshot is not None:
        try:
            _reinstate_admin(snapshot)
        except Exception as exc:  # noqa: BLE001
            logger.exception("Failed to re-insert admin: %s", exc)
            return 1

    logger.info("Row counts AFTER:")
    show_table_counts()
    logger.info("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
