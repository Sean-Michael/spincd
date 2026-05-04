from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlmodel import SQLModel
from sqlalchemy import Engine
from contextlib import asynccontextmanager
import logging
import os

# Local modules
from .config import Settings, get_settings
from .database import get_engine
from .routers import albums


def init_logger(settings: Settings):
    """Initialize logger with handlers"""
    console_handler = logging.StreamHandler()
    console_handler.setLevel(settings.log_level)
    console_handler.setFormatter(logging.Formatter(settings.console_format))
    logging.basicConfig(level=logging.DEBUG, handlers=[console_handler])
    logging.info("Setup logging handler(s)...")


def create_db_and_tables(engine: Engine):
    """Create the tables for all table SQLModel models"""
    SQLModel.metadata.create_all(engine)
    logging.info("Created db and tables...")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown dependencies and lifecycle of FastAPI app"""
    init_logger(get_settings())
    create_db_and_tables(get_engine())
    yield


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

_DIST = os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")

if os.path.isdir(_DIST):
    app.mount("/assets", StaticFiles(directory=os.path.join(_DIST, "assets")), name="assets")

    @app.get("/")
    async def index():
        return FileResponse(os.path.join(_DIST, "index.html"))

    @app.get("/{full_path:path}")
    async def spa_fallback(full_path: str):
        return FileResponse(os.path.join(_DIST, "index.html"))

else:
    @app.get("/")
    async def root():
        return {"message": "hello spincd!"}
