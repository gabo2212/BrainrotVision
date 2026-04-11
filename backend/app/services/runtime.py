from __future__ import annotations

from brainrotvision.artifacts import ArtifactRuntime
from brainrotvision.config import AppSettings, get_settings


def create_runtime(settings: AppSettings | None = None) -> ArtifactRuntime:
    return ArtifactRuntime(settings or get_settings())
