from __future__ import annotations

from pathlib import Path

from PIL import Image

from brainrotvision.config import AppSettings
from brainrotvision.dataset import build_metadata, download_dataset, resolve_dataset_root


def _make_image(path: Path, color: tuple[int, int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (64, 48), color=color)
    image.save(path)


def test_resolve_dataset_root_prefers_nested_image_directory(tmp_path: Path):
    data_dir = tmp_path / "data"
    dataset_root = data_dir / "raw" / "brainrot_dataset"
    _make_image(dataset_root / "alpha" / "a.png", (255, 0, 0))
    _make_image(dataset_root / "beta" / "b.png", (0, 255, 0))

    settings = AppSettings(_env_file=None, DATA_DIR=str(data_dir), ARTIFACTS_DIR=str(tmp_path / "artifacts"))
    assert resolve_dataset_root(settings) == dataset_root


def test_build_metadata_creates_files_and_infers_labels(tmp_path: Path):
    data_dir = tmp_path / "data"
    dataset_root = data_dir / "raw" / "brainrot_dataset"
    _make_image(dataset_root / "alpha" / "a.png", (255, 0, 0))
    _make_image(dataset_root / "beta" / "b.png", (0, 255, 0))

    settings = AppSettings(_env_file=None, DATA_DIR=str(data_dir), ARTIFACTS_DIR=str(tmp_path / "artifacts"))
    metadata = build_metadata(settings)

    assert len(metadata) == 2
    assert set(metadata["label"].dropna()) == {"alpha", "beta"}
    assert settings.metadata_csv_path.exists()
    assert settings.metadata_parquet_path.exists()
    assert settings.stats_json_path.exists()
    assert any(settings.thumbnails_dir.iterdir())


def test_download_dataset_without_credentials_raises_helpful_error(tmp_path: Path, monkeypatch):
    monkeypatch.setenv("HOME", str(tmp_path))
    monkeypatch.delenv("KAGGLE_USERNAME", raising=False)
    monkeypatch.delenv("KAGGLE_KEY", raising=False)
    settings = AppSettings(_env_file=None, DATA_DIR=str(tmp_path / "data"), ARTIFACTS_DIR=str(tmp_path / "artifacts"))

    try:
        download_dataset(settings)
    except RuntimeError as exc:
        assert "KAGGLE_USERNAME" in str(exc)
    else:
        raise AssertionError("download_dataset should require Kaggle credentials when none are configured")
