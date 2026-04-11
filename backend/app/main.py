from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from backend.app.routes.analyze import router as analyze_router
from backend.app.routes.dataset import router as dataset_router
from backend.app.routes.health import router as health_router
from backend.app.services.runtime import create_runtime
from brainrotvision.config import AppSettings, get_settings


def create_app(
    settings: AppSettings | None = None,
    runtime=None,
) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        if getattr(app.state, "runtime", None) is None:
            app.state.runtime = create_runtime(settings)
        yield

    app = FastAPI(
        title="BrainrotVision API",
        version="0.1.0",
        description="FastAPI backend for image analysis, similarity search, and dataset insights.",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    settings.raw_dir.mkdir(parents=True, exist_ok=True)
    settings.thumbnails_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/raw", StaticFiles(directory=settings.raw_dir), name="raw")
    app.mount("/thumbnails", StaticFiles(directory=settings.thumbnails_dir), name="thumbnails")

    if runtime is not None:
        app.state.runtime = runtime

    app.include_router(health_router)
    app.include_router(dataset_router)
    app.include_router(analyze_router)
    return app


app = create_app()
