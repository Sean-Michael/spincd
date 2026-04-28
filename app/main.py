from typing import Annotated
from fastapi import FastAPI, Form, Depends, HTTPException, Query
from sqlmodel import Field, Session, SQLModel, select
from contextlib import asynccontextmanager
import logging
from .config import Settings
from functools import lru_cache


class AlbumBase(SQLModel):
    """Base model for Albums with required and optional shared fields"""

    title: str
    artist: str = Field(index=True)  # Create an index for fast Artist lookups
    release_year: int | None = None
    genre: str | None = None
    label: str | None = None


class Album(AlbumBase, table=True):
    """Database Table model for Albums"""

    id: int | None = Field(default=None, primary_key=True)


class AlbumPublic(AlbumBase):
    """Public Album model returned to clients"""

    id: int


class AlbumCreate(AlbumBase):
    """Data model for Albums to validate form data from clients"""

    pass


class AlbumUpdate(SQLModel):
    """Provide all the optional fields so they can be updated"""

    title: str | None = None
    artist: str | None = None
    release_year: int | None = None
    genre: str | None = None
    label: str | None = None


@lru_cache
def get_settings() -> Settings:
    """Helper to grab settings and cache the result"""
    return Settings()


# Type alias for dependency injection
SettingsDep = Annotated[Settings, Depends(get_settings)]


def init_logger(settings: Settings):
    """Initialize logger with handlers"""
    # Logging to stdout
    console_handler = logging.StreamHandler()
    console_handler.setLevel(settings.log_level)
    console_handler.setFormatter(logging.Formatter(settings.console_format))

    logging.basicConfig(level=logging.DEBUG, handlers=[console_handler])
    logging.info("Setup logging handler(s)...")


def create_db_and_tables(settings: Settings):
    """# Create the tables for all table SQLModel models"""
    SQLModel.metadata.create_all(settings.engine)
    logging.info("Created db and tables...")


def get_session(settings: SettingsDep):
    """Creates a Session instance for storing objects in memory"""
    with Session(settings.engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_session)]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown dependencies and lifecycle of FastAPI app"""
    # Startup
    settings = get_settings()
    init_logger(settings)
    create_db_and_tables(settings)
    yield
    # Shutdown


# Initialize the FastAPI application
app = FastAPI(lifespan=lifespan)


async def acr(column, session: SessionDep):
    """Helper to DRY up add commit refresh"""
    try:
        session.add(column)
        session.commit()
        session.refresh(column)
        return
    except Exception as e:
        print(e)
        raise


@app.post("/albums", response_model=AlbumPublic)
async def create_album(album: Annotated[AlbumCreate, Form()], session: SessionDep):
    """Create a new Album record in DB"""
    db_album = Album.model_validate(album)
    await acr(db_album, session)
    return db_album


@app.get("/albums", response_model=list[AlbumPublic])
async def read_albums(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
):
    """Read all the albums in the collection"""
    albums = session.exec(select(Album).offset(offset).limit(limit)).all()
    return albums


@app.get("/albums/{album_id}", response_model=AlbumPublic)
async def read_album_by_id(album_id: int, session: SessionDep):
    """Read a single album by id"""
    album = session.get(Album, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    return album


@app.put("/albums/{album_id}", response_model=AlbumPublic)
async def replace_album_by_id(
    album_id: int, album: Annotated[AlbumCreate, Form()], session: SessionDep
):
    """Idempotent update of an entire Album in place"""
    album_db = session.get(Album, album_id)
    if not album_db:
        raise HTTPException(status_code=404, detail="Album not found")
    album_db.sqlmodel_update(album)
    await acr(album_db, session)
    return album_db


@app.patch("/albums/{album_id}", response_model=AlbumPublic)
async def update_album_by_id(album_id: int, album: AlbumUpdate, session: SessionDep):
    """Update specific Album fields"""
    album_db = session.get(Album, album_id)
    if not album_db:
        raise HTTPException(status_code=404, detail="Album not found")
    album_data = album.model_dump(exclude_unset=True)
    album_db.sqlmodel_update(album_data)
    await acr(album_db, session)
    return album_db


@app.delete("/albums/{album_id}")
async def delete_album_by_id(album_id: int, session: SessionDep):
    album = session.get(Album, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    session.delete(album)
    session.commit()
    return {"ok": True}
