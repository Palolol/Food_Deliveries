"""Firebase module removed — authentication now uses native JWT.

This file is kept as a no-op shim so any remaining import doesn't break.
"""

_firebase_app = None  # Always None; Firebase has been removed


def init_firebase() -> None:
    """No-op — Firebase Auth has been removed."""
    pass


def verify_firebase_token(id_token: str) -> dict:
    """Removed — use JWT-based auth instead."""
    raise NotImplementedError("Firebase Auth has been removed. Use JWT login.")
