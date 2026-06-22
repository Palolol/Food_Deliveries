"""Firebase Admin SDK initialization and token verification."""
from __future__ import annotations

import logging
import os
from typing import Optional

import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import settings

logger = logging.getLogger(__name__)

# Track initialization state to avoid re-initializing on hot-reload
_firebase_app: Optional[firebase_admin.App] = None


def _resolve_credentials_path() -> str:
    """Resolve the credentials path to an absolute file path."""
    path = settings.firebase_credentials_path
    if not os.path.isabs(path):
        # Make path relative to the backend/ root (where .env lives)
        backend_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
        path = os.path.join(backend_root, path)
    return path


def init_firebase() -> None:
    """Initialize Firebase Admin SDK exactly once."""
    global _firebase_app
    if _firebase_app is not None:
        return

    creds_path = _resolve_credentials_path()

    if not os.path.exists(creds_path):
        logger.warning(
            "Firebase credentials file not found at %s. "
            "Token verification will fail until this is provided.",
            creds_path,
        )
        # Initialize with the application default credentials fallback
        try:
            _firebase_app = firebase_admin.initialize_app(
                credential=credentials.ApplicationDefault(),
                options={"projectId": settings.firebase_project_id}
                if settings.firebase_project_id
                else None,
            )
            logger.info("Firebase Admin initialized with Application Default Credentials")
            return
        except Exception as exc:
            logger.error("Failed to initialize Firebase Admin: %s", exc)
            return

    try:
        cred = credentials.Certificate(creds_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin initialized using %s", creds_path)
    except Exception as exc:
        logger.error("Failed to initialize Firebase Admin SDK: %s", exc)
        raise


def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded claims.

    Raises:
        firebase_admin.auth.InvalidIdTokenError: when token is invalid/expired
        firebase_admin.auth.ExpiredIdTokenError: when token is expired
        firebase_admin.auth.RevokedIdTokenError: when token was revoked
    """
    if _firebase_app is None:
        # Lazy initialize if user forgot to call init_firebase() at startup
        init_firebase()
    decoded = auth.verify_id_token(id_token, check_revoked=True)
    return decoded


def get_firebase_user(uid: str) -> Optional[auth.UserRecord]:
    """Fetch a Firebase user record by UID."""
    if _firebase_app is None:
        init_firebase()
    try:
        return auth.get_user(uid)
    except auth.UserNotFoundError:
        return None
