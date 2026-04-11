from __future__ import annotations

from fastapi import APIRouter, Depends

from backend.app.dependencies import get_runtime
from backend.app.models.schemas import HealthResponse


router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health(runtime=Depends(get_runtime)) -> HealthResponse:
    return HealthResponse(**runtime.health())
