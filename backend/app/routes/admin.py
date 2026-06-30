"""Admin-only maintenance routes.

Endpoints:
  GET  /admin/db/table-counts   — current row counts (admin only)
  POST /admin/clear-db          — wipe all data from the database (admin only)

Safety:
  - ``require_admin`` dependency gates every endpoint.
  - Caller must set ``confirm: true`` in the request body.
  - Refuses to run unless ``APP_ENV`` is one of: development, dev, testing, test.
  - Each request is logged with the admin user's id + email.
  - By default the calling admin is re-inserted after the wipe so their JWT
    keeps working. Pass ``preserve_admin: false`` to wipe everything.
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import require_admin
from app.db.mssql import MSSQLBase, MSSQLSessionLocal, mssql_engine
from app.models.mssql.user import User, UserRole
from app.schemas.admin import ClearDBRequest, ClearDBResponse
from app.services.user_service import create_user, hash_password

# Reuse the existing clear_db helper for the canonical table order.
from app.clear_db import TABLES_IN_ORDER  # noqa: F401

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["Admin"])


# ── Helpers ───────────────────────────────────────────────────────────────────

ALLOWED_ENVS = {"development", "dev", "testing", "test"}


def _table_counts() -> Dict[str, int]:
    """Return a {table: row_count} mapping for every app table."""
    counts: Dict[str, int] = {}
    with mssql_engine.connect() as conn:
        for table in TABLES_IN_ORDER:
            counts[table] = int(
                conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar() or 0
            )
    return counts


def _snapshot_admin(admin: User, new_password_hash: Optional[str]) -> Dict:
    """Capture the fields needed to re-insert this admin row later.

    SQLAlchemy's Enum with ``native_enum=False`` stores the *name* of the
    enum value (e.g. ``"ADMIN"``), not the lowercase ``.value`` string.
    We must write it back the same way to keep SQLAlchemy's coercion happy.
    """
    return {
        "id": admin.id,
        "email": admin.email,
        "full_name": admin.full_name,
        "phone": admin.phone,
        "avatar_url": admin.avatar_url,
        "password_hash": new_password_hash or admin.password_hash,
        "role": admin.role.name if isinstance(admin.role, UserRole) else str(admin.role),
        "is_active": bool(admin.is_active),
    }


def _reinstate_admin(snapshot: Dict) -> User:
    """Re-insert the admin row, keeping the original id via IDENTITY_INSERT."""
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

    # Open a fresh session to read back the re-inserted row.
    with MSSQLSessionLocal() as db:
        return db.query(User).filter(User.id == snapshot["id"]).first()


def _clear_orm() -> None:
    """Delete every row in dependency order via SQLAlchemy ORM.

    SQL Server forbids multi-cascade-path cycles, so we removed
    ``ON DELETE CASCADE`` from the ``branch`` FKs (reviews.restaurant_id,
    payments.order_id). That means the DB won't auto-clean these tables
    when their grandparent row is deleted — we must do it in the right
    order: leaves first, users last.
    """
    from app.models.mssql.order import Order, OrderItem
    from app.models.mssql.payment import Payment
    from app.models.mssql.review import Review
    from app.models.mssql.address import Address
    from app.models.mssql.menu import MenuItem
    from app.models.mssql.restaurant import Restaurant

    with MSSQLSessionLocal() as db:
        db.query(OrderItem).delete(synchronize_session=False)
        db.query(Payment).delete(synchronize_session=False)
        db.query(Order).delete(synchronize_session=False)
        db.query(Review).delete(synchronize_session=False)
        db.query(Address).delete(synchronize_session=False)
        db.query(MenuItem).delete(synchronize_session=False)
        db.query(Restaurant).delete(synchronize_session=False)
        db.query(User).delete(synchronize_session=False)
        db.commit()


def _clear_truncate() -> None:
    """TRUNCATE every table.

    SQL Server's ``NOCHECK CONSTRAINT`` does NOT unblock TRUNCATE — TRUNCATE
    requires the FKs to be physically absent. We snapshot FK definitions,
    drop them, truncate, then restore them so the schema is unchanged.
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
            action_row = conn.execute(
                text("SELECT fk.delete_referential_action_desc FROM sys.foreign_keys fk WHERE fk.name = :name"),
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

    action_map = {
        "NO_ACTION": "NO ACTION",
        "CASCADE": "CASCADE",
        "SET_NULL": "SET NULL",
        "SET_DEFAULT": "SET DEFAULT",
    }

    logger.info("Dropping %d FK constraint(s)...", len(fk_snapshot))
    with mssql_engine.begin() as conn:
        for fk in fk_snapshot:
            conn.execute(text(f"ALTER TABLE [{fk['tbl']}] DROP CONSTRAINT [{fk['fk_name']}]"))
        for table in TABLES_IN_ORDER:
            logger.info("TRUNCATE %s", table)
            conn.execute(text(f"TRUNCATE TABLE {table}"))
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


def _clear_recreate() -> None:
    """DROP every table, then re-create from current models."""
    MSSQLBase.metadata.drop_all(bind=mssql_engine)
    MSSQLBase.metadata.create_all(bind=mssql_engine)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/db/table-counts",
    response_model=Dict[str, int],
    summary="Row counts for every application table (admin only)",
)
def get_table_counts(
    admin: User = Depends(require_admin),
) -> Dict[str, int]:
    logger.info("admin=%s requested table counts", admin.email)
    return _table_counts()


@router.post(
    "/clear-db",
    response_model=ClearDBResponse,
    status_code=status.HTTP_200_OK,
    summary="Wipe every row from the database (admin only)",
)
def clear_database(
    payload: ClearDBRequest,
    admin: User = Depends(require_admin),
) -> ClearDBResponse:
    # 1. Environment guard — refuse to wipe non-dev databases via HTTP.
    env = (settings.app_env or "").lower()
    if env not in ALLOWED_ENVS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"clear-db is disabled when APP_ENV={env!r}. "
                f"Allowed: {sorted(ALLOWED_ENVS)}."
            ),
        )

    # 2. Explicit confirmation in the body.
    if not payload.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Set `confirm: true` in the request body to proceed.",
        )

    new_password_hash: Optional[str] = None
    if payload.new_password:
        new_password_hash = hash_password(payload.new_password)

    logger.warning(
        "ADMIN %s (id=%s) requested clear_db mode=%r preserve_admin=%s",
        admin.email, admin.id, payload.mode, payload.preserve_admin,
    )

    rows_before = _table_counts()
    target_db = settings.mssql_database_uri.split("@")[-1]

    # 3. Snapshot the admin (with new password hash if provided) BEFORE the wipe.
    snapshot = _snapshot_admin(admin, new_password_hash) if payload.preserve_admin else None

    # 4. Run the wipe.
    try:
        if payload.mode == "delete":
            _clear_orm()
        elif payload.mode == "truncate":
            _clear_truncate()
        elif payload.mode == "recreate":
            _clear_recreate()
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unknown mode: {payload.mode!r}",
            )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.exception("clear-db failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"clear-db failed: {exc}",
        )

    # 5. Re-insert the admin if requested.
    admin_preserved = False
    preserved_email: Optional[str] = None
    preserved_id: Optional[int] = None

    if snapshot is not None:
        try:
            new_admin = _reinstate_admin(snapshot)
            admin_preserved = True
            preserved_email = new_admin.email
            preserved_id = new_admin.id
            logger.warning(
                "Admin re-inserted id=%s email=%s (preserved across wipe)",
                preserved_id, preserved_email,
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("Failed to re-insert admin after wipe: %s", exc)
            # Don't 500 — the wipe itself succeeded; just flag it.
            admin_preserved = False

    rows_after = _table_counts()

    logger.warning(
        "clear-db complete mode=%r before=%s after=%s by admin=%s preserved=%s",
        payload.mode, rows_before, rows_after, admin.email, admin_preserved,
    )

    return ClearDBResponse(
        status="ok",
        mode=payload.mode,
        database=target_db,
        environment=env,
        rows_before=rows_before,
        rows_after=rows_after,
        admin_preserved=admin_preserved,
        admin_email=preserved_email,
        admin_id=preserved_id,
        new_password_set=bool(new_password_hash),
    )
