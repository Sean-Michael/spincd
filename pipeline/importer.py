from __future__ import annotations

import base64
import json
from pathlib import Path

import httpx
from rich.console import Console

from pipeline.process import SCAN_TYPES, extract_colors

console = Console()


def _to_data_url(image_bytes: bytes) -> str:
    return f"data:image/jpeg;base64,{base64.b64encode(image_bytes).decode()}"


def run_bulk_import(
    metadata_path: Path,
    processed_dir: Path,
    api_url: str = "http://localhost:8000",
) -> None:
    """POST each entry in metadata_path to the spinCD API using processed scan images."""
    if not metadata_path.exists():
        console.print(f"[red]File not found: {metadata_path}[/red]")
        return

    try:
        entries = json.loads(metadata_path.read_text())
    except json.JSONDecodeError as e:
        console.print(f"[red]Invalid JSON: {e}[/red]")
        return

    if not isinstance(entries, list):
        console.print("[red]Expected a JSON array at the top level.[/red]")
        return

    base = api_url.rstrip("/")
    ok = err = 0

    console.print(f"\n[bold]Importing {len(entries)} album(s) → {base}[/bold]\n")

    for entry in entries:
        slug = (entry.get("slug") or "").strip()
        title = (entry.get("title") or "").strip()
        artist = (entry.get("artist") or "").strip()

        if not slug:
            console.print(f"[yellow]⚠  Skipping entry with no slug: {entry}[/yellow]")
            continue
        if not title or not artist:
            console.print(f"[yellow]⚠  [{slug}] missing title or artist — skipping.[/yellow]")
            continue

        scan_dir = processed_dir / slug
        scans: dict[str, str | None] = {t: None for t in SCAN_TYPES}
        hue: int | None = None
        accent: str | None = None

        for scan_type in SCAN_TYPES:
            p = scan_dir / f"{scan_type}.jpg"
            if not p.exists():
                continue
            data = p.read_bytes()
            scans[scan_type] = _to_data_url(data)
            if scan_type == "front" and hue is None:
                hue, accent = extract_colors(data)

        found = [t for t in SCAN_TYPES if scans[t]]
        if not found:
            console.print(
                f"  [yellow]⚠[/yellow]  [{slug}] no processed scans in {scan_dir} — "
                "importing metadata only"
            )

        payload = {
            "title": title,
            "artist": artist,
            "release_year": entry.get("release_year"),
            "genre": entry.get("genre") or [],
            "tracks": entry.get("tracks") or [],
            "label": entry.get("label"),
            "notes": entry.get("notes"),
            "hue": hue,
            "accent": accent,
            "scan_front": scans["front"],
            "scan_back": scans["back"],
            "scan_disc": scans["disc"],
        }

        try:
            with httpx.Client(timeout=60) as client:
                resp = client.post(f"{base}/albums/", json=payload)
                resp.raise_for_status()
                album_id = resp.json()["id"]
            scans_note = " ".join(found) or "no scans"
            console.print(
                f"  [green]✓[/green]  id={album_id:<5} "
                f"[bold]{artist}[/bold] — {title}  [{scans_note}]"
            )
            ok += 1
        except httpx.HTTPStatusError as e:
            console.print(
                f"  [red]✗[/red]  {artist} — {title}: "
                f"HTTP {e.response.status_code}  {e.response.text[:120]}"
            )
            err += 1
        except Exception as e:
            console.print(f"  [red]✗[/red]  {artist} — {title}: {e}")
            err += 1

    console.print(f"\n[bold]Done.[/bold] {ok} imported, {err} failed.")
