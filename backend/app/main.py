"""FastAPI application entry point.

Architecture:
- Single MSSQL database for all data (users, restaurants, menus, reviews,
  addresses, orders, payments)
- JWT-based authentication (Firebase removed)
- Role-based access: admin, customer, restaurant_owner
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.db.mssql import test_mssql_connection
from app.routes.auth import router as auth_router
from app.routes.addresses import router as address_router
from app.routes.menu import router as menu_router
from app.routes.reviews import router as review_router
from app.routes.orders import router as orders_router
from app.routes.payments import router as payments_router
from app.routes.restaurants import router as restaurants_router
from app.routes.admin import router as admin_router
from app.schemas.common import HealthResponse

logging.basicConfig(
    level=logging.INFO if not settings.app_debug else logging.DEBUG,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks."""
    logger.info("Starting %s in %s mode", settings.app_name, settings.app_env)
    logger.info("MSSQL reachable: %s", test_mssql_connection())
    yield
    logger.info("Shutting down %s", settings.app_name)


app = FastAPI(
    title=settings.app_name,
    version="2.0.0",
    description=(
        "Food Delivery API — single MSSQL database, JWT authentication, "
        "role-based access (admin / customer / restaurant_owner)."
    ),
    debug=settings.app_debug,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_prefix = settings.api_prefix

app.include_router(auth_router,        prefix=api_prefix)
app.include_router(restaurants_router, prefix=api_prefix)
app.include_router(menu_router,        prefix=api_prefix)
app.include_router(address_router,     prefix=api_prefix)
app.include_router(review_router,      prefix=api_prefix)
app.include_router(orders_router,      prefix=api_prefix)
app.include_router(payments_router,    prefix=api_prefix)
app.include_router(admin_router,       prefix=api_prefix)


@app.get("/", include_in_schema=False)
def root() -> dict:
    return {
        "name": settings.app_name,
        "version": "2.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
        "auth": "JWT (Bearer token)",
        "database": "MSSQL (single unified database)",
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
def health() -> HealthResponse:
    """Liveness + MSSQL reachability check."""
    return HealthResponse(
        status="ok",
        environment=settings.app_env,
        mssql=test_mssql_connection(),
        timestamp=datetime.utcnow(),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request, exc):  # noqa: ANN001
    logger.exception("Unhandled exception on %s %s", request.method, request.url)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )
