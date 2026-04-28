from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Settings fields with types and runtime defaults"""

    # LOGGING
    log_level: str = "DEBUG"
    console_format: str = "%(asctime)s - %(levelname)s - %(message)s"

    # DATABASE
    sqlite_file_name: str = "spincd.db"
    sqlite_url: str = f"sqlite:///{sqlite_file_name}"
    connect_args: dict = {"check_same_thread": False}  # Allows db access across threads
