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
    display_label: str | None = None
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


class PredictionOptionResponse(BaseModel):
    class_id: int | None = None
    label: str
    display_label: str
    confidence: float


class NeighborAgreementResponse(BaseModel):
    agrees_with_prediction: bool
    agreement_ratio: float
    matching_neighbors: int
    total_neighbors: int
    majority_label: str | None = None
    majority_display_label: str | None = None


class ClusterAlignmentResponse(BaseModel):
    cluster_id: int | None = None
    aligns_with_prediction: bool
    majority_label: str | None = None
    majority_display_label: str | None = None
    majority_ratio: float | None = None


class ClassificationResponse(BaseModel):
    class_id: int | None = None
    label: str
    display_label: str
    confidence: float
    classifier_available: bool = True
    classifier_status: str
    confidence_gap: float | None = None
    wording: str = "Detected Brainrot"
    low_confidence: bool = False
    open_set_warning: bool = False
    warning_message: str | None = None
    top_predictions: list[PredictionOptionResponse] = Field(default_factory=list)
    neighbor_agreement: NeighborAgreementResponse | None = None
    cluster_alignment: ClusterAlignmentResponse | None = None
    evidence: list[str] = Field(default_factory=list)


class AnalyzeResponse(BaseModel):
    filename: str
    width: int
    height: int
    format: str
    brightness: float
    contrast: float
    classifier_available: bool = False
    cluster_id: int | None = None
    classification: ClassificationResponse | None = None
    similar_images: list[SampleImageResponse] = Field(default_factory=list)
    upload_sha256: str | None = None


class AnalyzeSampleRequest(BaseModel):
    raw_relative_path: str


class AnalyzeUrlRequest(BaseModel):
    url: str


class SimilarResponse(BaseModel):
    filename: str
    cluster_id: int | None = None
    similar_images: list[SampleImageResponse] = Field(default_factory=list)


class SamplesEnvelope(BaseModel):
    items: list[SampleImageResponse]


class StatsEnvelope(BaseModel):
    payload: dict[str, Any]
