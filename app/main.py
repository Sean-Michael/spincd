from fastapi import FastAPI
from sqlmodel import SQLModel, Session
from sqlalchemy import Engine
from contextlib import asynccontextmanager
import logging

# Local modules
from .config import Settings, get_settings
from .database import get_engine
from .routers import albums


def acr(data, session: Session):
    """Helper to DRY up add commit refresh"""
    session.add(data)
    session.commit()
    session.refresh(data)


def init_logger(settings: Settings):
    """Initialize logger with handlers"""
    # Logging to stdout
    console_handler = logging.StreamHandler()
    console_handler.setLevel(settings.log_level)
    console_handler.setFormatter(logging.Formatter(settings.console_format))
    logging.basicConfig(level=logging.DEBUG, handlers=[console_handler])
    logging.info("Setup logging handler(s)...")


def create_db_and_tables(engine: Engine):
    """# Create the tables for all table SQLModel models"""
    SQLModel.metadata.create_all(engine)
    logging.info("Created db and tables...")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown dependencies and lifecycle of FastAPI app"""
    # Startup
    init_logger(get_settings())
    create_db_and_tables(get_engine())
    yield
    # Shutdown


# Initialize the FastAPI application
app = FastAPI(lifespan=lifespan)

# /albums
app.include_router(albums.router)


@app.get("/")
async def root():
    return {"message": "hello spincd!"}
