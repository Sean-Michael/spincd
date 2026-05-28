from __future__ import annotations

from pathlib import Path

import typer
from rich.console import Console

app = typer.Typer(name="pipeline", help="spinCD scan pipeline", add_completion=False)
console = Console()

_RAW_DIR = Path("scans/raw")
_PROCESSED_DIR = Path("scans/processed")
_API_URL = "http://localhost:8000"


@app.command()
def process(
    scan_dir: Path = typer.Option(_RAW_DIR, "--scan-dir", "-s", help="Raw scans input directory"),
    processed_dir: Path = typer.Option(_PROCESSED_DIR, "--out", "-o", help="Processed output directory"),
    fuzz: int = typer.Option(5, "--fuzz", help="(unused) legacy ImageMagick trim fuzz %%"),
    size: int = typer.Option(1417, "--size", help="Output cover size in pixels (square)"),
    reprocess: bool = typer.Option(False, "--reprocess", help="Re-process already-processed files"),
    rotations: Path = typer.Option(
        Path("scans/rotations.json"), "--rotations",
        help="JSON map of manual orientation overrides: {slug: {front|back|disc: 90|180|270}}",
    ),
) -> None:
    """Deskew, crop, and square raw scans into the processed folder."""
    from pipeline.process import run_process
    run_process(
        scan_dir=scan_dir,
        processed_dir=processed_dir,
        fuzz_pct=fuzz,
        cover_size=size,
        skip_existing=not reprocess,
        rotations_path=rotations,
    )


@app.command("bulk-import")
def bulk_import(
    metadata: Path = typer.Argument(..., help="Path to albums metadata JSON file"),
    processed_dir: Path = typer.Option(_PROCESSED_DIR, "--processed", "-p", help="Directory of processed scans"),
    api_url: str = typer.Option(_API_URL, "--api", help="spinCD API base URL"),
) -> None:
    """Import albums from a JSON metadata file, attaching processed scan images."""
    from pipeline.importer import run_bulk_import
    run_bulk_import(
        metadata_path=metadata,
        processed_dir=processed_dir,
        api_url=api_url,
    )


@app.command("upload")
def upload(
    processed_dir: Path = typer.Option(_PROCESSED_DIR, "--processed", "-p", help="Directory of processed scans"),
    bucket: str = typer.Option(..., "--bucket", "-b", envvar="S3_SCAN_BUCKET", help="Target S3 bucket"),
    prefix: str = typer.Option("scans", "--prefix", help="Key prefix within the bucket"),
    region: str = typer.Option(None, "--region", envvar="AWS_REGION", help="AWS region"),
    dry_run: bool = typer.Option(False, "--dry-run", help="List uploads without writing to S3"),
) -> None:
    """Upload processed scans to S3 (matches the layout seed.py builds URLs for)."""
    from pipeline.upload import run_upload
    run_upload(
        processed_dir=processed_dir,
        bucket=bucket,
        prefix=prefix,
        region=region,
        dry_run=dry_run,
    )


if __name__ == "__main__":
    app()
