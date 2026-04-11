from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    project_name: str = "BrainrotVision"
    kaggle_dataset_slug: str = Field(
        default="bubblepw/italian-brainrot-images",
        alias="KAGGLE_DATASET_SLUG",
    )
    data_dir: Path = Field(default=Path("data"), alias="DATA_DIR")
    artifacts_dir: Path = Field(default=Path("ml/artifacts"), alias="ARTIFACTS_DIR")
    backend_host: str = Field(default="0.0.0.0", alias="BACKEND_HOST")
    backend_port: int = Field(default=8000, alias="BACKEND_PORT")
    api_base_url: str = Field(default="http://127.0.0.1:8000", alias="API_BASE_URL")
    device: str = Field(default="cpu", alias="BRAINROTVISION_DEVICE")
    random_seed: int = 42
    thumbnail_size: int = 256
    sample_gallery_size: int = 16
    kmeans_clusters: int = 8

    @property
    def raw_dir(self) -> Path:
        return self.data_dir / "raw"

    @property
    def dataset_zip_path(self) -> Path:
        return self.raw_dir / "brainrot_dataset.zip"

    @property
    def extracted_dataset_dir(self) -> Path:
        return self.raw_dir / "brainrot_dataset"

    @property
    def processed_dir(self) -> Path:
        return self.data_dir / "processed"

    @property
    def thumbnails_dir(self) -> Path:
        return self.data_dir / "thumbnails"

    @property
    def metadata_csv_path(self) -> Path:
        return self.processed_dir / "metadata.csv"

    @property
    def metadata_parquet_path(self) -> Path:
        return self.processed_dir / "metadata.parquet"

    @property
    def stats_json_path(self) -> Path:
        return self.processed_dir / "dataset_stats.json"

    @property
    def plots_dir(self) -> Path:
        return self.processed_dir / "plots"

    @property
    def reports_dir(self) -> Path:
        return self.processed_dir / "reports"


@lru_cache(maxsize=1)
def get_settings() -> AppSettings:
    return AppSettings()
