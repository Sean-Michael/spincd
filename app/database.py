from sqlmodel import create_engine
from functools import lru_cache
from sqlalchemy import Engine
from sqlmodel import Session
from typing import Annotated
from fastapi import Depends

# Local modules
from .config import get_settings


@lru_cache
def get_engine() -> Engine:
    """Helper to get engine as cached dependency provider"""
    settings = get_settings()
    url = settings.database_url or f"sqlite:///{settings.sqlite_file_name}"
    connect_args = {"check_same_thread": False} if url.startswith("sqlite") else {}
    return create_engine(url, connect_args=connect_args)


def get_session(engine: Annotated[Engine, Depends(get_engine)]):
    """Creates a Session instance for storing objects in memory"""
    with Session(engine) as session:
        yield session
