from __future__ import annotations

from collections import Counter
import hashlib
import json
import random
from io import BytesIO
from pathlib import Path
from typing import Any

import imagehash
import joblib
import numpy as np
import pandas as pd
from PIL import Image
from sklearn.cluster import DBSCAN, KMeans
from sklearn.decomposition import PCA
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, f1_score
from sklearn.model_selection import train_test_split
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import LabelEncoder

from .config import AppSettings
from .dataset import (
    build_metadata,
    extract_image_statistics,
    load_metadata,
    resolve_dataset_root,
    summarize_metadata,
)
from .embeddings import EmbeddingExtractor, normalize_embeddings
from .utils import LOGGER, ensure_directories, write_json


EMBEDDINGS_PATH = "embeddings.npy"
NN_MODEL_PATH = "nearest_neighbors.joblib"
KMEANS_PATH = "kmeans.joblib"
DBSCAN_PATH = "dbscan.joblib"
CLASSIFIER_PATH = "classifier.joblib"
PROJECTION_PATH = "embedding_projection.csv"
MANIFEST_PATH = "manifest.json"
LOW_CONFIDENCE_THRESHOLD = 0.6
LOW_CONFIDENCE_GAP_THRESHOLD = 0.12
OPEN_SET_CONFIDENCE_THRESHOLD = 0.4
OPEN_SET_NEIGHBOR_AGREEMENT_THRESHOLD = 0.4


def _artifact_path(settings: AppSettings, name: str) -> Path:
    return settings.artifacts_dir / name


def _choose_kmeans_clusters(settings: AppSettings, sample_count: int) -> int:
    if sample_count < 2:
        return 0
    heuristic = int(np.sqrt(sample_count))
    return max(2, min(settings.kmeans_clusters, heuristic if heuristic > 1 else 2, sample_count))


def _display_label(label: str | None) -> str | None:
    if label is None:
        return None
    if pd.isna(label):
        return None
    parts = [part for part in str(label).replace("-", "_").split("_") if part]
    if not parts:
        return None
    return " ".join(part.capitalize() for part in parts)


def _build_cluster_profiles(metadata: pd.DataFrame) -> dict[int, dict[str, Any]]:
    if metadata.empty or "kmeans_cluster" not in metadata.columns or "label" not in metadata.columns:
        return {}

    labelled = metadata[
        metadata["kmeans_cluster"].notna() & metadata["label"].notna()
    ].copy()
    if labelled.empty:
        return {}

    profiles: dict[int, dict[str, Any]] = {}
    for cluster_id, frame in labelled.groupby("kmeans_cluster"):
        counts = frame["label"].astype(str).value_counts()
        majority_label = str(counts.index[0])
        majority_count = int(counts.iloc[0])
        total_items = int(len(frame))
        profiles[int(cluster_id)] = {
            "majority_label": majority_label,
            "majority_display_label": _display_label(majority_label),
            "majority_ratio": round(majority_count / total_items, 4) if total_items else None,
            "total_items": total_items,
        }
    return profiles


def _fit_optional_classifier(metadata: pd.DataFrame, embeddings: np.ndarray) -> dict[str, Any] | None:
    labelled = metadata[metadata["label"].notna()].copy()
    if labelled.empty:
        return None

    counts = labelled["label"].value_counts()
    supported_labels = counts[counts >= 2].index.tolist()
    labelled = labelled[labelled["label"].isin(supported_labels)]
    if labelled["label"].nunique() < 2 or len(labelled) < 8:
        return None

    rows = labelled["embedding_row"].astype(int).to_numpy()
    x = embeddings[rows]
    y = labelled["label"].astype(str).to_numpy()

    x_train, x_test, y_train, y_test = train_test_split(
        x,
        y,
        test_size=0.25,
        random_state=42,
        stratify=y,
    )
    encoder = LabelEncoder()
    y_train_encoded = encoder.fit_transform(y_train)
    y_test_encoded = encoder.transform(y_test)

    model = LogisticRegression(max_iter=2000, n_jobs=None)
    model.fit(x_train, y_train_encoded)
    predictions = model.predict(x_test)
    metrics = {
        "accuracy": round(float(accuracy_score(y_test_encoded, predictions)), 4),
        "macro_f1": round(float(f1_score(y_test_encoded, predictions, average="macro")), 4),
        "classes": encoder.classes_.tolist(),
    }
    return {
        "model": model,
        "label_encoder": encoder,
        "metrics": metrics,
    }


def _save_projection(
    settings: AppSettings,
    metadata: pd.DataFrame,
    embeddings: np.ndarray,
) -> pd.DataFrame:
    if len(embeddings) < 2:
        projection = metadata[["filename", "label", "kmeans_cluster", "dbscan_cluster"]].copy()
        projection["pca_x"] = 0.0
        projection["pca_y"] = 0.0
        projection.to_csv(_artifact_path(settings, PROJECTION_PATH), index=False)
        return projection

    pca = PCA(n_components=2, random_state=settings.random_seed)
    coords = pca.fit_transform(embeddings)
    projection = metadata[["filename", "label", "kmeans_cluster", "dbscan_cluster"]].copy()
    projection["pca_x"] = coords[:, 0]
    projection["pca_y"] = coords[:, 1]
    projection.to_csv(_artifact_path(settings, PROJECTION_PATH), index=False)
    return projection


def build_artifacts(settings: AppSettings) -> dict[str, Any]:
    ensure_directories([settings.artifacts_dir, settings.processed_dir, settings.plots_dir, settings.reports_dir])
    metadata = load_metadata(settings)
    if metadata.empty:
        metadata = build_metadata(settings)

    valid = metadata[metadata["is_valid"]].copy().reset_index(drop=True)
    if valid.empty:
        raise RuntimeError("No valid images were found. Build metadata after downloading the dataset.")

    image_paths = [Path(path) for path in valid["path"].tolist()]
    extractor = EmbeddingExtractor(device=settings.device)
    embeddings = extractor.embed_paths(image_paths)
    normalized_embeddings = normalize_embeddings(embeddings)
    np.save(_artifact_path(settings, EMBEDDINGS_PATH), normalized_embeddings)

    neighbors = NearestNeighbors(metric="cosine", n_neighbors=min(6, len(valid)))
    neighbors.fit(normalized_embeddings)
    joblib.dump(neighbors, _artifact_path(settings, NN_MODEL_PATH))

    cluster_count = _choose_kmeans_clusters(settings, len(valid))
    if cluster_count > 0:
        kmeans = KMeans(n_clusters=cluster_count, random_state=settings.random_seed, n_init="auto")
        valid["kmeans_cluster"] = kmeans.fit_predict(normalized_embeddings)
        joblib.dump(kmeans, _artifact_path(settings, KMEANS_PATH))
    else:
        valid["kmeans_cluster"] = -1

    if len(valid) >= 4:
        dbscan = DBSCAN(eps=0.35, min_samples=2, metric="euclidean")
        valid["dbscan_cluster"] = dbscan.fit_predict(normalized_embeddings)
        joblib.dump(dbscan, _artifact_path(settings, DBSCAN_PATH))
    else:
        valid["dbscan_cluster"] = -1

    valid["embedding_row"] = np.arange(len(valid))
    classifier_bundle = _fit_optional_classifier(valid, normalized_embeddings)
    classifier_metrics: dict[str, Any] | None = None
    if classifier_bundle:
        classifier_metrics = classifier_bundle["metrics"]
        joblib.dump(classifier_bundle, _artifact_path(settings, CLASSIFIER_PATH))

    metadata = metadata.drop(
        columns=[
            column
            for column in ["embedding_row", "kmeans_cluster", "dbscan_cluster"]
            if column in metadata.columns
        ],
        errors="ignore",
    )
    metadata = metadata.merge(
        valid[
            [
                "path",
                "embedding_row",
                "kmeans_cluster",
                "dbscan_cluster",
            ]
        ],
        on="path",
        how="left",
    )
    metadata.to_csv(settings.metadata_csv_path, index=False)
    metadata.to_parquet(settings.metadata_parquet_path, index=False)

    projection = _save_projection(settings, valid, normalized_embeddings)
    manifest = {
        "embedding_model": "torchvision_resnet50_default",
        "device": extractor.device,
        "samples_indexed": len(valid),
        "kmeans_clusters": int(cluster_count),
        "classifier_available": classifier_bundle is not None,
    }
    write_json(_artifact_path(settings, MANIFEST_PATH), manifest)

    stats = summarize_metadata(metadata)
    stats.update(
        {
            "dataset_root": str(resolve_dataset_root(settings)),
            "dataset_slug": settings.kaggle_dataset_slug,
            "dataset_zip_path": str(settings.dataset_zip_path) if settings.dataset_zip_path.exists() else None,
            "dataset_source": "repo_local_zip" if settings.dataset_zip_path.exists() else "filesystem",
            "kmeans_cluster_distribution": {
                str(key): int(value)
                for key, value in valid["kmeans_cluster"].value_counts().sort_index().items()
            },
            "dbscan_cluster_distribution": {
                str(key): int(value)
                for key, value in valid["dbscan_cluster"].value_counts().sort_index().items()
            },
            "classifier": classifier_metrics,
            "artifact_manifest": manifest,
        }
    )
    write_json(settings.stats_json_path, stats)
    LOGGER.info("Built ML artifacts for %s images", len(valid))
    return {
        "metadata": metadata,
        "projection": projection,
        "manifest": manifest,
        "stats": stats,
    }


class ArtifactRuntime:
    def __init__(self, settings: AppSettings) -> None:
        self.settings = settings
        self.initialization_error: str | None = None
        self.metadata = pd.DataFrame()
        self.valid = pd.DataFrame()
        self.extractor = None
        self.neighbors = None
        self.kmeans = None
        self.classifier_bundle = None
        self.embeddings = None
        self.cluster_profiles: dict[int, dict[str, Any]] = {}
        self.stats: dict[str, Any] = {
            "artifact_ready": False,
            "dataset_slug": settings.kaggle_dataset_slug,
        }

        try:
            self.metadata = load_metadata(settings)
            if not self.metadata.empty and "embedding_row" in self.metadata.columns:
                self.valid = self.metadata[self.metadata["embedding_row"].notna()].copy()
                if not self.valid.empty:
                    self.valid["embedding_row"] = self.valid["embedding_row"].astype(int)
                    self.valid = self.valid.sort_values("embedding_row").reset_index(drop=True)
                    self.cluster_profiles = _build_cluster_profiles(self.valid)

            self.extractor = EmbeddingExtractor(device=settings.device)
            self.neighbors = self._safe_load_joblib(NN_MODEL_PATH)
            self.kmeans = self._safe_load_joblib(KMEANS_PATH)
            self.classifier_bundle = self._safe_load_joblib(CLASSIFIER_PATH)
            self.embeddings = self._safe_load_embeddings()
            self.stats = self._safe_load_stats()
        except Exception as exc:  # noqa: BLE001
            self.initialization_error = str(exc)
            LOGGER.warning("Artifact runtime initialized in degraded mode: %s", exc)
            self.stats["detail"] = self.initialization_error

    def _safe_load_joblib(self, name: str) -> Any | None:
        path = _artifact_path(self.settings, name)
        if not path.exists():
            return None
        return joblib.load(path)

    def _safe_load_embeddings(self) -> np.ndarray | None:
        path = _artifact_path(self.settings, EMBEDDINGS_PATH)
        if not path.exists():
            return None
        return np.load(path)

    def _safe_load_stats(self) -> dict[str, Any]:
        if self.settings.stats_json_path.exists():
            return json.loads(self.settings.stats_json_path.read_text(encoding="utf-8"))
        return summarize_metadata(self.metadata)

    @property
    def classifier_available(self) -> bool:
        return self.classifier_bundle is not None

    @property
    def ready(self) -> bool:
        return (
            self.initialization_error is None
            and self.neighbors is not None
            and self.embeddings is not None
            and not self.valid.empty
        )

    def health(self) -> dict[str, Any]:
        return {
            "ready": self.ready,
            "samples_indexed": int(len(self.valid)),
            "classifier_available": self.classifier_available,
        }

    def get_stats(self) -> dict[str, Any]:
        payload = dict(self.stats)
        payload["artifact_ready"] = self.ready
        return payload

    def get_samples(self, limit: int = 12) -> list[dict[str, Any]]:
        if self.valid.empty:
            return []
        sample_size = min(limit, len(self.valid))
        records = self.valid.sample(n=sample_size, random_state=random.randint(0, 1_000_000)).to_dict(
            orient="records"
        )
        return [self._serialize_sample(record) for record in records]

    def _serialize_sample(self, record: dict[str, Any], distance: float | None = None) -> dict[str, Any]:
        raw_relative = record.get("raw_relative_path")
        thumbnail_path = record.get("thumbnail_path")
        label = record.get("label")
        if pd.isna(label):
            label = None
        return {
            "filename": record.get("filename"),
            "label": label,
            "display_label": _display_label(label),
            "kmeans_cluster": _maybe_int(record.get("kmeans_cluster")),
            "dbscan_cluster": _maybe_int(record.get("dbscan_cluster")),
            "width": _maybe_int(record.get("width")),
            "height": _maybe_int(record.get("height")),
            "format": record.get("format"),
            "distance": round(float(distance), 4) if distance is not None else None,
            "raw_relative_path": raw_relative,
            "thumbnail_path": thumbnail_path,
            "raw_url": f"/raw/{raw_relative}" if raw_relative else None,
            "thumbnail_url": f"/thumbnails/{thumbnail_path}" if thumbnail_path else None,
        }

    def _classifier_status(self) -> str:
        if self.classifier_bundle is None:
            return "Unavailable for this dataset"
        encoder = self.classifier_bundle["label_encoder"]
        return f"Active on {len(encoder.classes_)} known dataset classes"

    def _summarize_neighbor_agreement(
        self,
        predicted_label: str,
        similar_images: list[dict[str, Any]],
    ) -> dict[str, Any] | None:
        labels = [str(item["label"]) for item in similar_images if item.get("label")]
        if not labels:
            return None

        counts = Counter(labels)
        majority_label, majority_count = counts.most_common(1)[0]
        matching_neighbors = counts.get(predicted_label, 0)
        total_neighbors = len(labels)
        agreement_ratio = round(matching_neighbors / total_neighbors, 4)
        return {
            "agrees_with_prediction": majority_label == predicted_label,
            "agreement_ratio": agreement_ratio,
            "matching_neighbors": matching_neighbors,
            "total_neighbors": total_neighbors,
            "majority_label": majority_label,
            "majority_display_label": _display_label(majority_label),
        }

    def _summarize_cluster_alignment(
        self,
        cluster_id: int | None,
        predicted_label: str,
    ) -> dict[str, Any] | None:
        if cluster_id is None:
            return None
        profile = self.cluster_profiles.get(int(cluster_id))
        if profile is None:
            return {
                "cluster_id": int(cluster_id),
                "aligns_with_prediction": False,
                "majority_label": None,
                "majority_display_label": None,
                "majority_ratio": None,
            }
        return {
            "cluster_id": int(cluster_id),
            "aligns_with_prediction": profile.get("majority_label") == predicted_label,
            "majority_label": profile.get("majority_label"),
            "majority_display_label": profile.get("majority_display_label"),
            "majority_ratio": profile.get("majority_ratio"),
        }

    def _build_classification_payload(
        self,
        embedding: np.ndarray,
        *,
        cluster_id: int | None,
        similar_images: list[dict[str, Any]],
    ) -> dict[str, Any] | None:
        if self.classifier_bundle is None:
            return None

        model = self.classifier_bundle["model"]
        encoder = self.classifier_bundle["label_encoder"]
        probabilities = model.predict_proba(embedding)[0]
        ranked_indices = np.argsort(probabilities)[::-1]
        top_predictions: list[dict[str, Any]] = []
        for class_index in ranked_indices[:3]:
            label = str(encoder.inverse_transform([int(class_index)])[0])
            top_predictions.append(
                {
                    "class_id": int(class_index),
                    "label": label,
                    "display_label": _display_label(label),
                    "confidence": round(float(probabilities[int(class_index)]), 4),
                }
            )

        winner = top_predictions[0]
        runner_up = top_predictions[1] if len(top_predictions) > 1 else None
        confidence_gap = round(
            winner["confidence"] - (runner_up["confidence"] if runner_up else 0.0),
            4,
        )
        neighbor_agreement = self._summarize_neighbor_agreement(winner["label"], similar_images)
        cluster_alignment = self._summarize_cluster_alignment(cluster_id, winner["label"])

        low_confidence = (
            winner["confidence"] < LOW_CONFIDENCE_THRESHOLD
            or confidence_gap < LOW_CONFIDENCE_GAP_THRESHOLD
        )
        open_set_warning = (
            winner["confidence"] < OPEN_SET_CONFIDENCE_THRESHOLD
            or (
                neighbor_agreement is not None
                and neighbor_agreement["agreement_ratio"] < OPEN_SET_NEIGHBOR_AGREEMENT_THRESHOLD
            )
        )
        wording = "Detected Brainrot"
        if open_set_warning:
            wording = "Best Match"
        elif low_confidence:
            wording = "Likely Identity"

        evidence = [
            f"Classifier ranked {winner['display_label']} first at {winner['confidence'] * 100:.1f}%.",
        ]
        if runner_up is not None:
            evidence.append(
                f"The margin over {runner_up['display_label']} is {confidence_gap * 100:.1f} points."
            )
        if neighbor_agreement is not None:
            evidence.append(
                f"{neighbor_agreement['matching_neighbors']} of {neighbor_agreement['total_neighbors']} nearest neighbors are also {winner['display_label']}."
            )
        if cluster_alignment is not None and cluster_alignment.get("majority_display_label") is not None:
            alignment_label = cluster_alignment["majority_display_label"]
            if cluster_alignment["aligns_with_prediction"]:
                evidence.append(
                    f"Cluster {cluster_alignment['cluster_id']} is mostly {alignment_label} examples."
                )
            else:
                evidence.append(
                    f"Cluster {cluster_alignment['cluster_id']} is mostly {alignment_label}, which weakens the identity call."
                )

        warning_message = None
        if open_set_warning:
            warning_message = (
                "Low confidence recognition: this image may sit outside the strongest known dataset patterns."
            )
        elif low_confidence:
            warning_message = (
                "This is the closest known identity, but the evidence is more mixed than usual."
            )

        return {
            "class_id": winner["class_id"],
            "label": winner["label"],
            "display_label": winner["display_label"],
            "confidence": winner["confidence"],
            "classifier_available": True,
            "classifier_status": self._classifier_status(),
            "confidence_gap": confidence_gap,
            "wording": wording,
            "low_confidence": low_confidence,
            "open_set_warning": open_set_warning,
            "warning_message": warning_message,
            "top_predictions": top_predictions,
            "neighbor_agreement": neighbor_agreement,
            "cluster_alignment": cluster_alignment,
            "evidence": evidence,
        }

    def _analyze_pil_image(
        self,
        image: Image.Image,
        *,
        filename: str | None = None,
        image_format: str | None = None,
    ) -> dict[str, Any]:
        brightness, contrast = extract_image_statistics(image)
        embedding = normalize_embeddings(np.expand_dims(self.extractor.embed_pil_image(image), axis=0))

        result: dict[str, Any] = {
            "filename": filename or "uploaded-image",
            "width": image.width,
            "height": image.height,
            "format": image_format or image.format or "UNKNOWN",
            "brightness": round(brightness, 4),
            "contrast": round(contrast, 4),
            "classifier_available": self.classifier_available,
            "cluster_id": None,
            "classification": None,
            "similar_images": [],
        }

        if self.kmeans is not None:
            result["cluster_id"] = int(self.kmeans.predict(embedding)[0])

        if self.neighbors is not None and not self.valid.empty:
            distances, indices = self.neighbors.kneighbors(
                embedding,
                n_neighbors=min(5, len(self.valid)),
            )
            result["similar_images"] = [
                self._serialize_sample(self.valid.iloc[int(index)].to_dict(), float(distance))
                for distance, index in zip(distances[0], indices[0], strict=True)
            ]

        if self.classifier_bundle is not None:
            result["classification"] = self._build_classification_payload(
                embedding,
                cluster_id=result["cluster_id"],
                similar_images=result["similar_images"],
            )

        return result

    def analyze_bytes(self, content: bytes, filename: str | None = None) -> dict[str, Any]:
        with Image.open(BytesIO(content)) as image:
            image.load()
            image_format = image.format
            rgb = image.convert("RGB")
            result = self._analyze_pil_image(rgb, filename=filename, image_format=image_format)
            sha256 = hashlib.sha256(content).hexdigest()
            result["upload_sha256"] = sha256
            return result

    def analyze_sample(self, raw_relative_path: str) -> dict[str, Any]:
        if not raw_relative_path:
            raise ValueError("A raw_relative_path value is required.")
        if self.valid.empty:
            raise ValueError("No indexed samples are available.")

        matches = self.valid[self.valid["raw_relative_path"] == raw_relative_path]
        if matches.empty:
            raise FileNotFoundError(f"Dataset sample not found for path '{raw_relative_path}'.")

        record = matches.iloc[0].to_dict()
        image_path = self.settings.raw_dir / raw_relative_path
        if not image_path.exists():
            raise FileNotFoundError(f"Dataset sample file does not exist at '{raw_relative_path}'.")

        with Image.open(image_path) as image:
            image.load()
            image_format = image.format
            rgb = image.convert("RGB")
            result = self._analyze_pil_image(
                rgb,
                filename=record.get("filename") or image_path.name,
                image_format=image_format,
            )

        sha256 = record.get("sha256")
        result["upload_sha256"] = None if pd.isna(sha256) else str(sha256)
        return result

    def similar_bytes(self, content: bytes, filename: str | None = None) -> dict[str, Any]:
        result = self.analyze_bytes(content, filename=filename)
        return {
            "filename": result["filename"],
            "cluster_id": result["cluster_id"],
            "similar_images": result["similar_images"],
        }


def _maybe_int(value: Any) -> int | None:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return None
    return int(value)
