from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    ready: bool
    samples_indexed: int
    classifier_available: bool


class SampleImageResponse(BaseModel):
    filename: str | None = None
    label: str | None = None
    kmeans_cluster: int | None = None
    dbscan_cluster: int | None = None
    width: int | None = None
    height: int | None = None
    format: str | None = None
    distance: float | None = None
    raw_relative_path: str | None = None
    thumbnail_path: str | None = None
    raw_url: str | None = None
    thumbnail_url: str | None = None


class ClassificationResponse(BaseModel):
    label: str
    confidence: float


class AnalyzeResponse(BaseModel):
    filename: str
    width: int
    height: int
    format: str
    brightness: float
    contrast: float
    cluster_id: int | None = None
    classification: ClassificationResponse | None = None
    similar_images: list[SampleImageResponse] = Field(default_factory=list)
    upload_sha256: str | None = None


class SimilarResponse(BaseModel):
    filename: str
    cluster_id: int | None = None
    similar_images: list[SampleImageResponse] = Field(default_factory=list)


class SamplesEnvelope(BaseModel):
    items: list[SampleImageResponse]


class StatsEnvelope(BaseModel):
    payload: dict[str, Any]
