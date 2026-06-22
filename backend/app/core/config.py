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

    # MySQL
    mysql_server: str = "localhost"
    mysql_port: int = 3306
    mysql_database: str = "food_delivery"
    mysql_username: str = "root"
    mysql_password: str = ""
    mysql_driver: str = "mysql+pymysql"

    # MSSQL
    mssql_odbc_connection_string: Optional[str] = (
        "mssql+pyodbc://sa:Rata123@127.0.0.1:1444/food_delivery_finance?driver=ODBC+Driver+17+for+SQL+Server"
    )

    # Firebase
    firebase_credentials_path: str = "firebase.json"
    firebase_project_id: str = ""
    firebase_api_key: str = ""

    # Security
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 60

    # ---------- Computed URIs ----------
    @property
    def mysql_database_uri(self) -> str:
        """Build MySQL connection URI for SQLAlchemy."""
        return (
            f"{self.mysql_driver}://{self.mysql_username}:{self.mysql_password}"
            f"@{self.mysql_server}:{self.mysql_port}/{self.mysql_database}"
            f"?charset=utf8mb4"
        )

    @property
    def mssql_database_uri(self) -> str:
        """Build MSSQL connection URI for SQLAlchemy using pyodbc."""
        if self.mssql_odbc_connection_string:
            return self.mssql_odbc_connection_string
        return (
            f"mssql+pyodbc://{self.mssql_username}:{self.mssql_password}"
            f"@{self.mssql_server}:{self.mssql_port}/{self.mssql_database}"
            f"?driver={self.mssql_driver.replace(' ', '+')}"
        )


@lru_cache
def get_settings() -> Settings:
    """Cached settings accessor."""
    return Settings()


settings = get_settings()
