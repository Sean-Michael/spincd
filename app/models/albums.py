from sqlmodel import SQLModel, Field


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
