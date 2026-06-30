"""Application configuration via environment variables."""
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Centralized application settings loaded from .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_name: str = "Food Delivery API"
    app_env: str = "development"
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    api_prefix: str = "/api/v1"

    # MSSQL — single unified database for all data
    mssql_odbc_connection_string: Optional[str] = (
        "mssql+pyodbc://sa:Rata123@127.0.0.1:1444/food_delivery"
        "?driver=ODBC+Driver+17+for+SQL+Server"
    )

    # JWT Security
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 60
    algorithm: str = "HS256"

    # ---------- Computed URI ----------
    @property
    def mssql_database_uri(self) -> str:
        """MSSQL connection URI for SQLAlchemy."""
        if self.mssql_odbc_connection_string:
            return self.mssql_odbc_connection_string
        raise ValueError("MSSQL_ODBC_CONNECTION_STRING must be set in .env")


@lru_cache
def get_settings() -> Settings:
    """Cached settings accessor."""
    return Settings()


settings = get_settings()
