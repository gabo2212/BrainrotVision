from __future__ import annotations

import ipaddress
import urllib.parse
from io import BytesIO

import httpx
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from backend.app.dependencies import get_runtime
from backend.app.models.schemas import (
    AnalyzeResponse,
    AnalyzeSampleRequest,
    AnalyzeUrlRequest,
    ClassificationResponse,
    SimilarResponse,
)

# Maximum image size fetched from external URLs (10 MB)
_MAX_EXTERNAL_BYTES = 10 * 1024 * 1024

# Allowlist of trusted external image hostnames
_ALLOWED_HOSTS = {
    "upload.wikimedia.org",
    "commons.wikimedia.org",
    "static.wikitide.net",
    "italianbrainrot.miraheze.org",
    "i.imgur.com",
    "cdn.discordapp.com",
    "media.discordapp.net",
}


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


def _validate_external_url(url: str) -> str:
    """Validate that the URL is http/https and points to an allowed host."""
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only http/https URLs are supported.",
        )
    host = parsed.hostname or ""
    # Block private / loopback / link-local addresses
    try:
        addr = ipaddress.ip_address(host)
        if addr.is_private or addr.is_loopback or addr.is_link_local:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="URL resolves to a disallowed network address.",
            )
    except ValueError:
        pass  # hostname is not a bare IP — allowlist check below covers it
    if host not in _ALLOWED_HOSTS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Host '{host}' is not in the allowed external image list.",
        )
    return url


@router.post("/analyze/url", response_model=AnalyzeResponse)
async def analyze_url(
    request: AnalyzeUrlRequest,
    runtime=Depends(get_runtime),
) -> AnalyzeResponse:
    """Fetch an image from an external URL and run the full analysis pipeline."""
    if not runtime.ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Artifacts are not ready. Run `make metadata`, `make eda`, and `make artifacts` first.",
        )
    url = _validate_external_url(request.url)
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=15) as client:
            resp = await client.get(url, headers={"User-Agent": "BrainrotVision/1.0"})
            resp.raise_for_status()
            content_length = int(resp.headers.get("content-length", 0))
            if content_length > _MAX_EXTERNAL_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail="External image exceeds the 10 MB size limit.",
                )
            image_bytes = resp.content
            if len(image_bytes) > _MAX_EXTERNAL_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail="External image exceeds the 10 MB size limit.",
                )
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to fetch image: HTTP {exc.response.status_code}",
        ) from exc
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Network error fetching image: {exc}",
        ) from exc

    filename = urllib.parse.urlparse(url).path.rsplit("/", 1)[-1] or "external.jpg"
    payload = runtime.analyze_bytes(image_bytes, filename=filename)
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
