from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from backend.app.dependencies import get_runtime
from backend.app.models.schemas import SamplesEnvelope, StatsEnvelope


router = APIRouter(tags=["dataset"])


@router.get("/stats", response_model=StatsEnvelope)
def stats(runtime=Depends(get_runtime)) -> StatsEnvelope:
    return StatsEnvelope(payload=runtime.get_stats())


@router.get("/samples", response_model=SamplesEnvelope)
def samples(
    limit: int = Query(default=12, ge=1, le=48),
    runtime=Depends(get_runtime),
) -> SamplesEnvelope:
    return SamplesEnvelope(items=runtime.get_samples(limit=limit))
