from __future__ import annotations

from pathlib import Path

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from rich.console import Console

console = Console()

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}


def run_upload(
    processed_dir: Path,
    bucket: str,
    prefix: str = "scans",
    region: str | None = None,
    dry_run: bool = False,
) -> None:
    """Upload processed scan images to s3://{bucket}/{prefix}/{slug}/{face}.jpg.

    Mirrors the on-disk layout so URLs match what seed.py builds from
    SCAN_BASE_URL = https://{bucket}.s3.{region}.amazonaws.com/{prefix}
    """
    processed_dir = processed_dir.resolve()
    if not processed_dir.is_dir():
        console.print(f"[red]Processed dir not found: {processed_dir}[/red]")
        return

    files = sorted(
        p for p in processed_dir.rglob("*")
        if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS
    )
    if not files:
        console.print(f"[dim]No images found under {processed_dir}[/dim]")
        return

    prefix = prefix.strip("/")
    console.print(
        f"\n[bold]Uploading {len(files)} image(s)[/bold] → "
        f"s3://{bucket}/{prefix}/" + ("  [yellow](dry run)[/yellow]" if dry_run else "")
    )

    client = None if dry_run else boto3.client("s3", region_name=region)
    ok = failed = 0

    for path in files:
        rel = path.relative_to(processed_dir).as_posix()
        key = f"{prefix}/{rel}"
        if dry_run:
            console.print(f"  [dim]would put[/dim] {key}")
            ok += 1
            continue
        try:
            client.upload_file(
                str(path), bucket, key,
                ExtraArgs={"ContentType": "image/jpeg", "CacheControl": "public, max-age=31536000"},
            )
            console.print(f"  [green]✓[/green] {key}")
            ok += 1
        except (BotoCoreError, ClientError) as e:
            console.print(f"  [red]✗[/red] {key}: {e}")
            failed += 1

    parts = [f"[green]{ok} uploaded[/green]"]
    if failed:
        parts.append(f"[red]{failed} failed[/red]")
    console.print(f"\n[bold]Done.[/bold] {', '.join(parts)}.")
    if not dry_run and not failed:
        console.print(
            f"[dim]Set on the app:[/dim] SCAN_BASE_URL="
            f"https://{bucket}.s3.{region or '<region>'}.amazonaws.com/{prefix}"
        )
