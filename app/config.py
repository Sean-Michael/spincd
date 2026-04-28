from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Settings fields with types and runtime defaults"""

    # LOGGING
    log_level: str = "DEBUG"
    console_format: str = "%(asctime)s - %(levelname)s - %(message)s"

    # DATABASE
    sqlite_file_name: str = "spincd.db"
    database_url: str | None = None


@lru_cache
def get_settings() -> Settings:
    """Helper to grab settings and cache the result"""
    return Settings()
