"""FastAPI application entry point.

Bootstraps:
- Firebase Admin SDK
- MySQL + MSSQL engines
- Route registration
- Health check
- CORS (permissive default — tighten via env in production)
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.firebase import init_firebase
from app.db.mssql import test_mssql_connection
from app.db.mysql import test_mysql_connection
from app.routes.auth import router as auth_router
from app.routes.addresses import router as address_router
from app.routes.menu import router as menu_router
from app.routes.reviews import router as review_router
from app.routes.orders import router as orders_router
from app.routes.payments import router as payments_router
from app.routes.restaurants import router as restaurants_router
from app.schemas.common import HealthResponse

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO if not settings.app_debug else logging.DEBUG,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------
# App lifecycle
# ---------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks."""
    logger.info("Starting %s in %s mode", settings.app_name, settings.app_env)
    try:
        init_firebase()
    except Exception as exc:  # noqa: BLE001
        logger.error("Firebase init failed at startup: %s", exc)

    # Log DB reachability (do NOT crash the app — endpoints will return 503 on failure)
    logger.info("MySQL reachable: %s", test_mysql_connection())
    logger.info("MSSQL reachable: %s", test_mssql_connection())

    yield

    logger.info("Shutting down %s", settings.app_name)


# ---------------------------------------------------------------------
# App
# ---------------------------------------------------------------------
app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description=(
        "Production-ready FastAPI backend for the Food Delivery System. "
        "Authentication is delegated to Firebase Auth; this API verifies "
        "Firebase ID tokens and persists data across MySQL (application) "
        "and MSSQL (financial)."
    ),
    debug=settings.app_debug,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS — adjust allow_origins per environment
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: lock down in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------
api_prefix = settings.api_prefix

app.include_router(auth_router, prefix=api_prefix)
app.include_router(restaurants_router, prefix=api_prefix)
app.include_router(menu_router, prefix=api_prefix)
app.include_router(address_router, prefix=api_prefix)
app.include_router(review_router, prefix=api_prefix)
app.include_router(orders_router, prefix=api_prefix)
app.include_router(payments_router, prefix=api_prefix)


# ---------------------------------------------------------------------
# Root + health
# ---------------------------------------------------------------------
@app.get("/", include_in_schema=False)
def root() -> dict:
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
def health() -> HealthResponse:
    """Liveness + DB/Firebase reachability check."""
    from app.core.firebase import _firebase_app  # local import to avoid coupling

    return HealthResponse(
        status="ok",
        environment=settings.app_env,
        mysql=test_mysql_connection(),
        mssql=test_mssql_connection(),
        firebase=_firebase_app is not None,
        timestamp=datetime.utcnow(),
    )


# ---------------------------------------------------------------------
# Global error handlers
# ---------------------------------------------------------------------
@app.exception_handler(Exception)
async def unhandled_exception_handler(request, exc):  # noqa: ANN001
    logger.exception("Unhandled exception on %s %s", request.method, request.url)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )
