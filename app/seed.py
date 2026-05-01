"""Seed the database with the curated 60-CD collection.

Usage: uv run python -m app.seed
"""

from sqlmodel import Session, SQLModel, select

from .database import get_engine
from .models.albums import Album
from .seed_data import SEED


def seed() -> int:
    engine = get_engine()
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        existing = session.exec(select(Album)).all()
        if existing:
            print(f"DB already has {len(existing)} albums; refusing to seed.")
            print("Delete spincd.db and re-run if you want to start fresh.")
            return 0

        for artist, title, year, genre, hue, accent, added, rating, notes, tracks in SEED:
            session.add(
                Album(
                    artist=artist,
                    title=title,
                    release_year=year,
                    genre=genre,
                    hue=hue,
                    accent=accent,
                    added=added,
                    rating=rating,
                    notes=notes,
                    tracks=tracks,
                )
            )
        session.commit()
        return len(SEED)


if __name__ == "__main__":
    n = seed()
    print(f"Seeded {n} albums.")
