#!/usr/bin/env python3
"""Regenerate the macOS app's bundled seed from the Python registry's seed data.

Run from the repository root (needs the project's Python environment):

    uv run python macos/scripts/generate_seed.py

Keys are the same snake_case column names the app's Album model decodes, and
scan values stay as `slug/face.jpg` paths so ScanStore can resolve them inside
the app bundle.
"""

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "macos/Sources/spinCD/Resources/Seed.json"

sys.path.insert(0, str(REPO))
from app.seed_data import SEED  # noqa: E402


def main() -> int:
    albums = []
    for entry in SEED:
        scans = entry.get("scans", {})
        albums.append(
            {
                "artist": entry["artist"],
                "title": entry["title"],
                "release_year": entry.get("release_year"),
                "genre": entry.get("genre", []),
                "tracks": entry.get("tracks", []),
                "label": entry.get("label"),
                "hue": entry.get("hue"),
                "accent": entry.get("accent"),
                "added": entry.get("added"),
                "rating": entry.get("rating"),
                "notes": entry.get("notes"),
                "scan_front": scans.get("front"),
                "scan_back": scans.get("back"),
                "scan_disc": scans.get("disc"),
            }
        )

    OUT.write_text(json.dumps(albums, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {len(albums)} albums to {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
