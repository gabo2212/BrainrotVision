from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from backend.app.dependencies import get_runtime
from backend.app.models.schemas import (
    AnalyzeResponse,
    AnalyzeSampleRequest,
    ClassificationResponse,
    SimilarResponse,
)


router = APIRouter(tags=["analysis"])


def _normalize_analyze_payload(payload: dict) -> AnalyzeResponse:
    classification = payload.get("classification")
    if classification is not None:
        payload["classification"] = ClassificationResponse(**classification)
    return AnalyzeResponse(**payload)


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    file: UploadFile = File(...),
    runtime=Depends(get_runtime),
) -> AnalyzeResponse:
    if not runtime.ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Artifacts are not ready. Run `make metadata`, `make eda`, and `make artifacts` first.",
        )
    payload = runtime.analyze_bytes(await file.read(), filename=file.filename)
    return _normalize_analyze_payload(payload)


@router.post("/analyze/sample", response_model=AnalyzeResponse)
async def analyze_sample(
    request: AnalyzeSampleRequest,
    runtime=Depends(get_runtime),
) -> AnalyzeResponse:
    if not runtime.ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Artifacts are not ready. Run `make metadata`, `make eda`, and `make artifacts` first.",
        )
    try:
        payload = runtime.analyze_sample(request.raw_relative_path)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    return _normalize_analyze_payload(payload)


@router.post("/similar", response_model=SimilarResponse)
async def similar(
    file: UploadFile = File(...),
    runtime=Depends(get_runtime),
) -> SimilarResponse:
    if not runtime.ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Artifacts are not ready. Run `make metadata`, `make eda`, and `make artifacts` first.",
        )
    payload = runtime.similar_bytes(await file.read(), filename=file.filename)
    return SimilarResponse(**payload)


@router.post("/predict", response_model=ClassificationResponse)
async def predict(
    file: UploadFile = File(...),
    runtime=Depends(get_runtime),
) -> ClassificationResponse:
    if not runtime.ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Artifacts are not ready. Run `make metadata`, `make eda`, and `make artifacts` first.",
        )
    if not runtime.classifier_available:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="A classifier was not trained for this dataset.",
        )
    payload = runtime.analyze_bytes(await file.read(), filename=file.filename)
    classification = payload.get("classification")
    if classification is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="A classifier was not trained for this dataset.",
        )
    return ClassificationResponse(**classification)
