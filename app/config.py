from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache


class Settings(BaseSettings):
    """Settings fields with types and runtime defaults"""

    # LOGGING
    log_level: str = "DEBUG"
    console_format: str = "%(asctime)s - %(levelname)s - %(message)s"

    # DATABASE
    sqlite_file_name: str = "spincd.db"
    database_url: str | None = None

    # SCANS
    # Base URL for processed scan images. Empty -> served locally at /scans
    # (scans/processed mounted by main.py). Set to an S3/CDN base in production.
    scan_base_url: str = ""

    # ORIGINS
    allow_origins: list[str] = ["http://localhost:5173"]
    allow_methods: list[str] = ["*"]
    allow_headers: list[str] = ["*"]

    @field_validator("allow_origins", mode="before")
    @classmethod
    def parse_origins(cls, v: object) -> object:
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v


@lru_cache
def get_settings() -> Settings:
    """Helper to grab settings and cache the result"""
    return Settings()
