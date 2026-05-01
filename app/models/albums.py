from sqlmodel import SQLModel, Field
from sqlalchemy import Column, JSON


class AlbumBase(SQLModel):
    """Base model for Albums with required and optional shared fields"""

    title: str
    artist: str = Field(index=True)  # Create an index for fast Artist lookups
    release_year: int | None = None
    genre: list[str] = Field(default_factory=list, sa_column=Column(JSON))
    tracks: list[str] = Field(default_factory=list, sa_column=Column(JSON))
    notes: str | None = None
    rating: int | None = None
    hue: int | None = None
    accent: str | None = None
    added: str | None = None
    scan_front: str | None = None
    scan_back: str | None = None
    scan_disc: str | None = None
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
    genre: list[str] | None = None
    tracks: list[str] | None = None
    notes: str | None = None
    rating: int | None = None
    hue: int | None = None
    accent: str | None = None
    added: str | None = None
    scan_front: str | None = None
    scan_back: str | None = None
    scan_disc: str | None = None
    label: str | None = None
