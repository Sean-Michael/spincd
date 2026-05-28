from __future__ import annotations

import colorsys
import subprocess
from pathlib import Path

import cv2
import numpy as np
from rich.console import Console

console = Console()

SCAN_TYPES = ("front", "back", "disc")
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".tiff", ".tif"}


def _parse_filename(stem: str) -> tuple[str, str] | None:
    """Extract (slug, scan_type) from a stem like 'artist-title_front'. Case-insensitive suffix."""
    for scan_type in SCAN_TYPES:
        if stem.lower().endswith(f"_{scan_type}"):
            slug = stem[: -(len(scan_type) + 1)]
            return slug, scan_type
    return None


def _to_square(img: np.ndarray, size: int) -> np.ndarray:
    """Scale to fill a square then center-crop, so the whole frame is filled with no distortion."""
    h, w = img.shape[:2]
    scale = size / min(h, w)
    resized = cv2.resize(img, (round(w * scale), round(h * scale)), interpolation=cv2.INTER_AREA)
    rh, rw = resized.shape[:2]
    y0 = (rh - size) // 2
    x0 = (rw - size) // 2
    return resized[y0:y0 + size, x0:x0 + size]


def _crop_rotated_rect(img: np.ndarray, rect) -> np.ndarray:
    """Deskew by the minimal angle that axis-aligns rect, then crop it out."""
    (cx, cy), (w, h), angle = rect
    if angle < -45:  # normalize to the smallest rotation that straightens edges
        angle += 90
        w, h = h, w
    M = cv2.getRotationMatrix2D((cx, cy), angle, 1.0)
    rot = cv2.warpAffine(
        img, M, (img.shape[1], img.shape[0]),
        flags=cv2.INTER_CUBIC, borderValue=(255, 255, 255),
    )
    w, h = int(round(w)), int(round(h))
    x0 = max(0, int(round(cx - w / 2)))
    y0 = max(0, int(round(cy - h / 2)))
    return rot[y0:y0 + h, x0:x0 + w]


def _apply_orientation(img: np.ndarray, degrees: int) -> np.ndarray:
    """Apply a manual clockwise rotation override of 0/90/180/270 degrees."""
    deg = degrees % 360
    if deg == 90:
        return cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
    if deg == 180:
        return cv2.rotate(img, cv2.ROTATE_180)
    if deg == 270:
        return cv2.rotate(img, cv2.ROTATE_90_COUNTERCLOCKWISE)
    return img


def _crop_cover(img: np.ndarray) -> np.ndarray:
    """Detect the jewel-case face against the scanner background, deskew, and crop to it."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    _, th = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, np.ones((25, 25), np.uint8))
    cnts, _ = cv2.findContours(th, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return img
    rect = cv2.minAreaRect(max(cnts, key=cv2.contourArea))
    crop = _crop_rotated_rect(img, rect)
    return crop if crop.size else img


def _crop_disc(img: np.ndarray) -> np.ndarray:
    """Detect the circular disc and crop to its square bounding box."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur = cv2.medianBlur(gray, 7)
    h, w = blur.shape
    circles = cv2.HoughCircles(
        blur, cv2.HOUGH_GRADIENT, dp=1.2, minDist=w,
        param1=100, param2=60,
        minRadius=int(w * 0.25), maxRadius=int(w * 0.55),
    )
    if circles is None:
        return _crop_cover(img)  # fall back to contour crop
    x, y, r = np.round(circles[0, 0]).astype(int)
    x0, y0 = max(0, x - r), max(0, y - r)
    x1, y1 = min(w, x + r), min(h, y + r)
    return img[y0:y1, x0:x1]


def _process(src: Path, scan_type: str, cover_size: int, rotate: int = 0) -> np.ndarray:
    img = cv2.imread(str(src))
    if img is None:
        raise ValueError(f"could not read image: {src}")
    crop = _crop_disc(img) if scan_type == "disc" else _crop_cover(img)
    crop = _apply_orientation(crop, rotate)
    return _to_square(crop, cover_size)


def extract_colors(image_bytes: bytes) -> tuple[int, str]:
    """Return (hue 0–360, '#RRGGBB') dominant non-neutral color. Falls back on failure."""
    try:
        result = subprocess.run(
            ["magick", "-", "-resize", "100x100", "-colors", "16",
             "-format", "%c", "histogram:info:"],
            input=image_bytes, capture_output=True, check=True,
        )
        best: tuple[int, int, int] | None = None
        best_score = -1.0
        for line in result.stdout.decode(errors="replace").splitlines():
            if "(" not in line or "#" not in line:
                continue
            try:
                count = int(line.split(":")[0].strip())
                rgb_part = line[line.index("(") + 1: line.index(")")]
                r, g, b = (int(float(x.strip())) for x in rgb_part.split(",")[:3])
                mx, mn = max(r, g, b) / 255, min(r, g, b) / 255
                sat = (mx - mn) / mx if mx else 0
                light = (mx + mn) / 2
                score = count * sat * (1 - abs(light - 0.5) * 2)
                if score > best_score:
                    best_score, best = score, (r, g, b)
            except (ValueError, IndexError):
                continue
        if best:
            r, g, b = best
            h, _, _ = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            return int(h * 360), f"#{r:02X}{g:02X}{b:02X}"
    except Exception:
        pass
    return 200, "#88C0D0"


def _load_rotations(path: Path) -> dict[str, dict[str, int]]:
    """Load manual orientation overrides: {slug: {scan_type: degrees}}. Missing/invalid -> {}."""
    if not path.exists():
        return {}
    import json

    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        console.print(f"[yellow]⚠  could not read rotations file {path}[/yellow]")
        return {}


def run_process(
    scan_dir: Path,
    processed_dir: Path,
    fuzz_pct: int = 5,
    cover_size: int = 1417,
    skip_existing: bool = True,
    rotations_path: Path | None = None,
) -> None:
    """Deskew, crop, and square all raw scans into processed_dir/{slug}/{type}.jpg."""
    scan_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)
    rotations = _load_rotations(rotations_path) if rotations_path else {}

    targets = []
    for path in sorted(scan_dir.iterdir()):
        if path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue
        parsed = _parse_filename(path.stem)
        if parsed is None:
            console.print(f"  [dim]skip[/dim] {path.name}  (no _front/_back/_disc suffix)")
            continue
        targets.append((path, *parsed))

    if not targets:
        console.print(
            "[dim]No matching scans found. "
            "Name files like: artist-title_front.jpg[/dim]"
        )
        return

    console.print(f"\n[bold]Processing {len(targets)} scan(s)...[/bold]")
    ok = skipped = failed = 0

    for path, slug, scan_type in targets:
        out_dir = processed_dir / slug
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{scan_type}.jpg"

        if skip_existing and out_path.exists():
            console.print(f"  [dim]─[/dim] {path.name}  (already done)")
            skipped += 1
            continue

        rotate = int(rotations.get(slug, {}).get(scan_type, 0))
        try:
            result = _process(path, scan_type, cover_size, rotate)
            if not cv2.imwrite(str(out_path), result, [cv2.IMWRITE_JPEG_QUALITY, 92]):
                raise ValueError("cv2.imwrite returned False")
            tag = f"  [dim](rotated {rotate}°)[/dim]" if rotate else ""
            console.print(f"  [green]✓[/green] {path.name}{tag}")
            ok += 1
        except Exception as e:
            console.print(f"  [red]✗[/red] {path.name}: {e}")
            failed += 1

    parts = []
    if ok:
        parts.append(f"[green]{ok} processed[/green]")
    if skipped:
        parts.append(f"[dim]{skipped} skipped[/dim]")
    if failed:
        parts.append(f"[red]{failed} failed[/red]")
    console.print(f"\n[bold]Done.[/bold] {', '.join(parts)}.")
