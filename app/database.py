from sqlmodel import create_engine
from functools import lru_cache
from sqlalchemy import Engine
from sqlmodel import Session
import logging

# Local modules
from .config import get_settings


@lru_cache
def get_engine() -> Engine:
    """Helper to get engine as cached dependency provider"""
    settings = get_settings()
    url = settings.database_url or f"sqlite:///{settings.sqlite_file_name}"
    connect_args = {"check_same_thread": False} if url.startswith("sqlite") else {}
    return create_engine(url, connect_args=connect_args)


def get_session(engine):
    """Creates a Session instance for storing objects in memory"""
    with Session(engine) as session:
        yield session


def acr(data, session: Session):
    """Helper to DRY up add commit refresh"""
    try:
        session.add(data)
        session.commit()
        session.refresh(data)
        return
    except Exception as e:
        logging.exception(e)
        raise
