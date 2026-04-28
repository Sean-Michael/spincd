from sqlmodel import select
from typing import Annotated
from fastapi import Query, HTTPException, APIRouter

# Local modules
from ..models.albums import Album, AlbumPublic, AlbumCreate, AlbumUpdate
from ..dependencies import SessionDep
from ..main import acr


router = APIRouter(prefix="/albums", tags=["albums"])


@router.post("/", response_model=AlbumPublic)
async def create_album(album: AlbumCreate, session: SessionDep):
    """Create a new Album record in DB"""
    db_album = Album.model_validate(album)
    acr(db_album, session)
    return db_album


@router.get("/", response_model=list[AlbumPublic])
async def read_albums(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
):
    """Read all the albums in the collection"""
    albums = session.exec(select(Album).offset(offset).limit(limit)).all()
    return albums


@router.get("/{album_id}", response_model=AlbumPublic)
async def read_album_by_id(album_id: int, session: SessionDep):
    """Read a single album by id"""
    album = session.get(Album, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    return album


@router.put("/{album_id}", response_model=AlbumPublic)
async def replace_album_by_id(album_id: int, album: AlbumCreate, session: SessionDep):
    """Idempotent update of an entire Album in place"""
    album_db = session.get(Album, album_id)
    if not album_db:
        raise HTTPException(status_code=404, detail="Album not found")
    album_db.sqlmodel_update(album)
    acr(album_db, session)
    return album_db


@router.patch("/{album_id}", response_model=AlbumPublic)
async def update_album_by_id(album_id: int, album: AlbumUpdate, session: SessionDep):
    """Update specific Album fields"""
    album_db = session.get(Album, album_id)
    if not album_db:
        raise HTTPException(status_code=404, detail="Album not found")
    album_data = album.model_dump(exclude_unset=True)
    album_db.sqlmodel_update(album_data)
    acr(album_db, session)
    return album_db


@router.delete("/{album_id}")
async def delete_album_by_id(album_id: int, session: SessionDep):
    album = session.get(Album, album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    session.delete(album)
    session.commit()
    return {"ok": True}
