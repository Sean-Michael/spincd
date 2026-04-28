from pydantic_settings import BaseSettings
from sqlmodel import create_engine
from sqlalchemy import Engine


class Settings(BaseSettings):
    """Settings fields with types and runtime defaults"""

    # LOGGING
    log_level: str = "DEBUG"
    console_format: str = "%(asctime)s - %(levelname)s - %(message)s"

    # DATABASE
    sqlite_file_name: str = "spincd.db"
    sqlite_url: str = f"sqlite:///{sqlite_file_name}"
    connect_args: dict = {"check_same_thread": False}  # Allows db access across threads
    engine: Engine = create_engine(sqlite_url, connect_args=connect_args)
