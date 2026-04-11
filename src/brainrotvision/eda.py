from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

from .artifacts import PROJECTION_PATH, _artifact_path
from .config import AppSettings
from .dataset import load_metadata, summarize_metadata
from .utils import LOGGER, ensure_directories


sns.set_theme(style="whitegrid")


def _save_figure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(path, dpi=180, bbox_inches="tight")
    plt.close()


def _plot_count_distribution(metadata: pd.DataFrame, settings: AppSettings) -> None:
    valid = metadata[metadata["is_valid"]]
    plt.figure(figsize=(8, 4))
    counts = valid["format"].fillna("UNKNOWN").value_counts()
    chart = counts.rename_axis("format").reset_index(name="count")
    sns.barplot(data=chart, x="format", y="count", hue="format", palette="crest", legend=False)
    plt.title("Image Format Distribution")
    plt.xlabel("Format")
    plt.ylabel("Count")
    _save_figure(settings.plots_dir / "format_distribution.png")


def _plot_numeric_distribution(metadata: pd.DataFrame, column: str, title: str, settings: AppSettings) -> None:
    valid = metadata[metadata["is_valid"] & metadata[column].notna()]
    if valid.empty:
        return
    plt.figure(figsize=(8, 4))
    sns.histplot(valid[column], bins=30, kde=True, color="#0f766e")
    plt.title(title)
    plt.xlabel(column.replace("_", " ").title())
    plt.ylabel("Frequency")
    _save_figure(settings.plots_dir / f"{column}_distribution.png")


def _plot_label_distribution(metadata: pd.DataFrame, settings: AppSettings) -> None:
    valid = metadata[metadata["is_valid"] & metadata["label"].notna()]
    if valid["label"].nunique() < 2:
        return
    top_counts = valid["label"].value_counts().head(12)
    chart = top_counts.rename_axis("label").reset_index(name="count")
    plt.figure(figsize=(10, 5))
    sns.barplot(data=chart, y="label", x="count", hue="label", palette="mako", legend=False)
    plt.title("Top Inferred Labels")
    plt.xlabel("Count")
    plt.ylabel("Label")
    _save_figure(settings.plots_dir / "label_distribution.png")


def _plot_sample_gallery(metadata: pd.DataFrame, settings: AppSettings) -> None:
    valid = metadata[metadata["is_valid"]].head(settings.sample_gallery_size)
    if valid.empty:
        return
    fig, axes = plt.subplots(4, 4, figsize=(12, 12))
    for axis, (_, row) in zip(axes.flatten(), valid.iterrows(), strict=False):
        thumbnail = settings.thumbnails_dir / str(row["thumbnail_path"])
        axis.imshow(plt.imread(thumbnail))
        axis.set_title(str(row["label"] or row["filename"])[:24], fontsize=8)
        axis.axis("off")
    for axis in axes.flatten()[len(valid) :]:
        axis.axis("off")
    fig.suptitle("Sample Gallery", fontsize=16)
    _save_figure(settings.plots_dir / "sample_gallery.png")


def _plot_embedding_projection(settings: AppSettings) -> None:
    projection_path = _artifact_path(settings, PROJECTION_PATH)
    if not projection_path.exists():
        return
    projection = pd.read_csv(projection_path)
    if projection.empty:
        return
    plt.figure(figsize=(8, 6))
    sns.scatterplot(
        data=projection,
        x="pca_x",
        y="pca_y",
        hue="kmeans_cluster",
        style="label" if projection["label"].notna().any() else None,
        palette="tab10",
        s=60,
    )
    plt.title("Embedding Projection (PCA)")
    plt.xlabel("PC 1")
    plt.ylabel("PC 2")
    _save_figure(settings.plots_dir / "embedding_projection.png")


def _write_summary(metadata: pd.DataFrame, settings: AppSettings) -> None:
    stats = summarize_metadata(metadata)
    lines = [
        "# EDA Summary",
        "",
        f"- Total images: {stats['total_images']}",
        f"- Valid images: {stats['valid_images']}",
        f"- Corrupt images: {stats['corrupt_images']}",
        f"- Unique formats: {len(stats['format_distribution'])}",
        f"- Has inferred labels: {stats['has_labels']}",
        f"- Exact duplicate groups: {stats['exact_duplicate_groups']}",
        f"- Near-duplicate groups: {stats['near_duplicate_groups']}",
        "",
        "## Notes",
        "",
        "- Similarity search and clustering are the primary analysis path.",
        "- Classification is enabled only if the folder structure exposes enough label diversity.",
        "- Embedding projection appears after `make artifacts` has been run.",
    ]
    report_path = settings.reports_dir / "eda_summary.md"
    report_path.write_text("\n".join(lines), encoding="utf-8")


def generate_eda(settings: AppSettings) -> None:
    ensure_directories([settings.processed_dir, settings.reports_dir, settings.plots_dir])
    metadata = load_metadata(settings)
    if metadata.empty:
        raise RuntimeError("Metadata is empty. Run `make metadata` after downloading the dataset.")

    LOGGER.info("Generating EDA plots in %s", settings.plots_dir)
    _plot_count_distribution(metadata, settings)
    _plot_numeric_distribution(metadata, "width", "Image Width Distribution", settings)
    _plot_numeric_distribution(metadata, "height", "Image Height Distribution", settings)
    _plot_numeric_distribution(metadata, "aspect_ratio", "Aspect Ratio Distribution", settings)
    _plot_numeric_distribution(metadata, "brightness", "Brightness Distribution", settings)
    _plot_numeric_distribution(metadata, "contrast", "Contrast Distribution", settings)
    _plot_label_distribution(metadata, settings)
    _plot_sample_gallery(metadata, settings)
    _plot_embedding_projection(settings)
    _write_summary(metadata, settings)
