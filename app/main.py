from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel
from sqlalchemy import Engine
from contextlib import asynccontextmanager
import logging

# Local modules
from .config import Settings, get_settings
from .database import get_engine
from .routers import albums


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

settings = get_settings()

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allow_origins,
    allow_credentials=True,
    allow_methods=settings.allow_methods,
    allow_headers=settings.allow_headers,
)

# /albums
app.include_router(albums.router)


@app.get("/")
async def root():
    return {"message": "hello spincd!"}
