"""Utility helpers."""
import secrets
import string
from datetime import datetime
from typing import Optional


def generate_order_number(prefix: str = "ORD", length: int = 10) -> str:
    """Generate a human-friendly order number, e.g. `ORD-3K9X2P1MRA`."""
    alphabet = string.ascii_uppercase + string.digits
    suffix = "".join(secrets.choice(alphabet) for _ in range(length))
    return f"{prefix}-{suffix}"


def generate_transaction_id(prefix: str = "TXN", length: int = 16) -> str:
    """Generate a unique transaction id, e.g. `TXN-9F3K...`."""
    alphabet = string.ascii_uppercase + string.digits
    suffix = "".join(secrets.choice(alphabet) for _ in range(length))
    return f"{prefix}-{suffix}"


def utcnow() -> datetime:
    """UTC-aware now."""
    return datetime.utcnow()
