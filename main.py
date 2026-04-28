from typing import Annotated

from fastapi import FastAPI, Form, Depends, HTTPException, Query
from sqlmodel import Field, Session, SQLModel, create_engine, select
from contextlib import asynccontextmanager


class AlbumBase(SQLModel):
    """Base model for Albums with shared fields"""

    title: str
    artist: str = Field(index=True)  # Create an index for fast Artist lookups
    release_year: int | None
    genre: str | None
    label: str | None


class Album(AlbumBase, table=True):
    """Database Table model for Albums"""

    id: int | None = Field(default=None, primary_key=True)


class AlbumPublic(AlbumBase):
    """Public Album model returned to clients"""

    id: int


class AlbumCreate(AlbumBase):
    """Data model for Albums to validate form data from clients"""

    pass


class AlbumUpdate(AlbumBase):
    """Provide all the fields of AlbumBase with defaults so they can be updated"""

    title: str | None = None
    artist: str | None = None
    release_year: int | None = None
    genre: str | None
    label: str | None


# Initialize the SQLModel Database Engine
sqlite_file_name = "spincd.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

connect_args = {"check_same_thread": False}  # Allows db access across threads
engine = create_engine(sqlite_url, connect_args=connect_args)


def create_db_and_tables():
    """# Create the tables for all table SQLModel models"""
    SQLModel.metadata.create_all(engine)


def get_session():
    """Creates a Session instance for storing objects in memory"""
    with Session(engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_session)]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown dependencies and lifecycle of FastAPI app"""
    # Startup
    create_db_and_tables()
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
