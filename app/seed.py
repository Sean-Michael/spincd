"""Seed the database with the curated scanned CD collection.

Usage: uv run python -m app.seed

Scan image URLs are built from each album's per-face scan path under
scans/processed, prefixed with Settings.scan_base_url (or "/scans" when that
is empty, which is served locally by the FastAPI app).
"""

from urllib.parse import quote

from sqlmodel import Session, SQLModel, select

from .config import get_settings
from .database import get_engine
from .models.albums import Album
from .seed_data import SEED


def _scan_url(path: str | None) -> str | None:
    """Build a scan image URL from a 'slug/face.jpg' path, or None if absent."""
    if not path:
        return None
    base = (get_settings().scan_base_url or "/scans").rstrip("/")
    return f"{base}/{quote(path)}"


def seed() -> int:
    engine = get_engine()
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        existing = session.exec(select(Album)).all()
        if existing:
            print(f"DB already has {len(existing)} albums; refusing to seed.")
            print("Delete spincd.db and re-run if you want to start fresh.")
            return 0

        for entry in SEED:
            scans = entry.get("scans", {})
            session.add(
                Album(
                    artist=entry["artist"],
                    title=entry["title"],
                    release_year=entry.get("release_year"),
                    genre=entry.get("genre", []),
                    tracks=entry.get("tracks", []),
                    label=entry.get("label"),
                    hue=entry.get("hue"),
                    accent=entry.get("accent"),
                    added=entry.get("added"),
                    rating=entry.get("rating"),
                    notes=entry.get("notes"),
                    scan_front=_scan_url(scans.get("front")),
                    scan_back=_scan_url(scans.get("back")),
                    scan_disc=_scan_url(scans.get("disc")),
                )
            )
        session.commit()
        return len(SEED)


if __name__ == "__main__":
    n = seed()
    print(f"Seeded {n} albums.")
