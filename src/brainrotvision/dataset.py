from __future__ import annotations

import hashlib
import os
import subprocess
import sys
import zipfile
from pathlib import Path
import shutil
from typing import Any

import imagehash
import numpy as np
import pandas as pd
from PIL import Image, ImageOps, ImageStat, UnidentifiedImageError

from .config import AppSettings
from .utils import LOGGER, ensure_directories, set_random_seed, write_json


IMAGE_EXTENSIONS = {
    ".bmp",
    ".gif",
    ".jpeg",
    ".jpg",
    ".png",
    ".tif",
    ".tiff",
    ".webp",
}


def has_kaggle_credentials() -> bool:
    if os.environ.get("KAGGLE_USERNAME") and os.environ.get("KAGGLE_KEY"):
        return True
    kaggle_json = Path.home() / ".kaggle" / "kaggle.json"
    return kaggle_json.exists()


def _count_image_files(path: Path) -> int:
    return sum(1 for item in path.rglob("*") if item.is_file() and item.suffix.lower() in IMAGE_EXTENSIONS)


def resolve_dataset_root(settings: AppSettings) -> Path:
    raw_dir = settings.raw_dir
    if not raw_dir.exists():
        raise FileNotFoundError(f"Raw data directory does not exist: {raw_dir}")

    if any(path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS for path in raw_dir.iterdir()):
        return raw_dir

    direct_child_dirs = [path for path in raw_dir.iterdir() if path.is_dir()]
    image_rich_children = [path for path in direct_child_dirs if _count_image_files(path) > 0]
    if len(image_rich_children) > 1:
        return raw_dir

    candidates = [path for path in raw_dir.rglob("*") if path.is_dir()]
    ranked = sorted(
        ((candidate, _count_image_files(candidate)) for candidate in candidates),
        key=lambda item: item[1],
        reverse=True,
    )
    for candidate, count in ranked:
        if count > 0:
            return candidate
    raise FileNotFoundError(
        f"No image files were found under {raw_dir}. Run `make data` after configuring Kaggle access."
    )


def list_image_files(dataset_root: Path) -> list[Path]:
    image_files = [
        path
        for path in dataset_root.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    ]
    return sorted(image_files)


def infer_label(relative_path: Path) -> str | None:
    parts = relative_path.parts[:-1]
    if not parts:
        return None
    return parts[0]


def compute_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _make_thumbnail(image: Image.Image, output_path: Path, size: int) -> None:
    thumbnail = image.copy()
    thumbnail.thumbnail((size, size))
    thumbnail.convert("RGB").save(output_path, format="JPEG", quality=90)


def extract_image_statistics(image: Image.Image) -> tuple[float, float]:
    grayscale = ImageOps.grayscale(image)
    stats = ImageStat.Stat(grayscale)
    mean = float(stats.mean[0])
    stddev = float(stats.stddev[0]) if stats.stddev else 0.0
    return mean, stddev


def build_record(
    image_path: Path,
    dataset_root: Path,
    settings: AppSettings,
) -> dict[str, Any]:
    relative_path = image_path.relative_to(dataset_root)
    raw_relative_path = image_path.relative_to(settings.raw_dir)
    record: dict[str, Any] = {
        "filename": image_path.name,
        "path": str(image_path),
        "relative_path": relative_path.as_posix(),
        "raw_relative_path": raw_relative_path.as_posix(),
        "label": infer_label(relative_path),
        "file_size_bytes": image_path.stat().st_size,
        "is_valid": False,
        "error": None,
        "width": None,
        "height": None,
        "format": None,
        "aspect_ratio": None,
        "sha256": None,
        "phash": None,
        "brightness": None,
        "contrast": None,
        "thumbnail_path": None,
    }

    try:
        with Image.open(image_path) as image:
            image.load()
            rgb_image = image.convert("RGB")
            width, height = rgb_image.size
            brightness, contrast = extract_image_statistics(rgb_image)
            sha256 = compute_sha256(image_path)
            phash = str(imagehash.phash(rgb_image))
            thumbnail_name = f"{sha256[:24]}.jpg"
            thumbnail_path = settings.thumbnails_dir / thumbnail_name
            if not thumbnail_path.exists():
                _make_thumbnail(rgb_image, thumbnail_path, settings.thumbnail_size)
            record.update(
                {
                    "is_valid": True,
                    "width": width,
                    "height": height,
                    "format": (image.format or image_path.suffix.removeprefix(".")).upper(),
                    "aspect_ratio": round(width / height, 4) if height else None,
                    "sha256": sha256,
                    "phash": phash,
                    "brightness": round(brightness, 4),
                    "contrast": round(contrast, 4),
                    "thumbnail_path": thumbnail_name,
                }
            )
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        record["error"] = str(exc)

    return record


def summarize_metadata(metadata: pd.DataFrame) -> dict[str, Any]:
    total_images = int(len(metadata))
    valid = metadata[metadata["is_valid"]]
    format_distribution = {
        str(key): int(value)
        for key, value in valid["format"].fillna("UNKNOWN").value_counts().sort_index().items()
    }
    label_distribution = {
        str(key): int(value)
        for key, value in valid["label"].dropna().value_counts().sort_values(ascending=False).items()
    }
    duplicate_sha = valid[valid["sha256"].notna()].groupby("sha256").size()
    duplicate_phash = valid[valid["phash"].notna()].groupby("phash").size()

    summary = {
        "total_images": total_images,
        "valid_images": int(valid["is_valid"].sum()),
        "corrupt_images": int((~metadata["is_valid"]).sum()),
        "format_distribution": format_distribution,
        "label_distribution": label_distribution,
        "has_labels": len(label_distribution) > 1,
        "width": _describe_numeric(valid["width"]),
        "height": _describe_numeric(valid["height"]),
        "aspect_ratio": _describe_numeric(valid["aspect_ratio"]),
        "brightness": _describe_numeric(valid["brightness"]),
        "contrast": _describe_numeric(valid["contrast"]),
        "exact_duplicate_groups": int((duplicate_sha > 1).sum()),
        "near_duplicate_groups": int((duplicate_phash > 1).sum()),
    }
    return summary


def _describe_numeric(series: pd.Series) -> dict[str, float | None]:
    cleaned = pd.to_numeric(series, errors="coerce").dropna()
    if cleaned.empty:
        return {
            "mean": None,
            "median": None,
            "min": None,
            "max": None,
        }
    return {
        "mean": round(float(cleaned.mean()), 4),
        "median": round(float(cleaned.median()), 4),
        "min": round(float(cleaned.min()), 4),
        "max": round(float(cleaned.max()), 4),
    }


def _write_duplicate_reports(metadata: pd.DataFrame, settings: AppSettings) -> None:
    valid = metadata[metadata["is_valid"]]
    exact_duplicates = valid.groupby("sha256").filter(lambda group: len(group) > 1)
    near_duplicates = valid.groupby("phash").filter(lambda group: len(group) > 1)
    exact_duplicates.to_csv(settings.reports_dir / "exact_duplicates.csv", index=False)
    near_duplicates.to_csv(settings.reports_dir / "near_duplicates.csv", index=False)


def build_metadata(settings: AppSettings) -> pd.DataFrame:
    set_random_seed(settings.random_seed)
    ensure_directories(
        [
            settings.raw_dir,
            settings.processed_dir,
            settings.reports_dir,
            settings.plots_dir,
            settings.thumbnails_dir,
        ]
    )
    dataset_root = resolve_dataset_root(settings)
    image_files = list_image_files(dataset_root)
    LOGGER.info("Building metadata for %s images from %s", len(image_files), dataset_root)

    records = [build_record(path, dataset_root, settings) for path in image_files]
    metadata = pd.DataFrame(records)
    metadata.to_csv(settings.metadata_csv_path, index=False)
    metadata.to_parquet(settings.metadata_parquet_path, index=False)
    _write_duplicate_reports(metadata, settings)
    summary = summarize_metadata(metadata)
    summary["dataset_root"] = str(dataset_root)
    summary["dataset_slug"] = settings.kaggle_dataset_slug
    summary["dataset_zip_path"] = str(settings.dataset_zip_path) if settings.dataset_zip_path.exists() else None
    summary["dataset_source"] = "repo_local_zip" if settings.dataset_zip_path.exists() else "filesystem"
    write_json(settings.stats_json_path, summary)
    return metadata


def load_metadata(settings: AppSettings) -> pd.DataFrame:
    if settings.metadata_parquet_path.exists():
        return pd.read_parquet(settings.metadata_parquet_path)
    if settings.metadata_csv_path.exists():
        return pd.read_csv(settings.metadata_csv_path)
    return build_metadata(settings)


def download_dataset(settings: AppSettings, force: bool = False) -> Path:
    ensure_directories([settings.raw_dir])
    if not force:
        try:
            existing_root = resolve_dataset_root(settings)
            LOGGER.info("Dataset already available at %s", existing_root)
            return existing_root
        except FileNotFoundError:
            pass

    if settings.dataset_zip_path.exists():
        dataset_root = extract_local_dataset_zip(settings, force=force)
        LOGGER.info("Using repo-local dataset zip at %s", settings.dataset_zip_path)
        return dataset_root

    if not has_kaggle_credentials():
        raise RuntimeError(
            f"Repo-local dataset zip was not found at {settings.dataset_zip_path}. "
            "Configure ~/.kaggle/kaggle.json or run "
            "`KAGGLE_USERNAME=your_username KAGGLE_KEY=your_key make data`."
        )

    command = [
        sys.executable,
        "-m",
        "kaggle",
        "datasets",
        "download",
        "-d",
        settings.kaggle_dataset_slug,
        "-p",
        str(settings.raw_dir),
        "--unzip",
    ]
    LOGGER.info("Downloading dataset with command: %s", " ".join(command))
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "Kaggle download failed.\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    dataset_root = resolve_dataset_root(settings)
    LOGGER.info("Dataset downloaded to %s", dataset_root)
    return dataset_root


def extract_local_dataset_zip(settings: AppSettings, force: bool = False) -> Path:
    zip_path = settings.dataset_zip_path
    if not zip_path.exists():
        raise FileNotFoundError(f"Dataset zip does not exist: {zip_path}")

    target_dir = settings.extracted_dataset_dir
    if force and target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path, "r") as archive:
        archive.extractall(target_dir)

    dataset_root = resolve_dataset_root(settings)
    return dataset_root
