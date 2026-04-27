from typing import Annotated

from fastapi import FastAPI, Form, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlmodel import Field, Session, SQLModel, create_engine, select
from contextlib import asynccontextmanager


class AlbumTable(SQLModel, table=True):
    """Database Table model for Albums"""

    id: int | None = Field(default=None, primary_key=True)
    title: str
    artist: str = Field(index=True)  # Create an index for fast Artist lookups
    release_year: int | None
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


@app.post("/albums")
async def create_album(
    album: Annotated[AlbumTable, Form()], session: SessionDep
) -> AlbumTable:
    """Create a new Album record in DB"""
    session.add(album)
    session.commit()
    session.refresh(album)
    return album


@app.get("/albums")
async def read_albums(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
) -> list[AlbumTable]:
    """Read all the albums in the collection"""
    albums = session.exec(select(AlbumTable).offset(offset).limit(limit)).all()
    return albums


@app.get("/albums/{album_id}")
async def read_album_by_id(album_id: int, session: SessionDep) -> AlbumTable:
    """Read a single album by id"""
    album = session.get(AlbumTable, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    return album


@app.put("/albums/{album_id}")
async def replace_album_by_id(album_id):
    return


@app.patch("/albums/{album_id}")
async def update_album_by_id(album_id):
    return


@app.delete("/albums/{album_id}")
async def delete_album_by_id(album_id, session: SessionDep):
    album = session.get(AlbumTable, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    session.delete(album)
    session.commit()
    return {"ok": True}
