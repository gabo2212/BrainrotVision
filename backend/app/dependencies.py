from __future__ import annotations

from fastapi import HTTPException, Request, status


def get_runtime(request: Request):
    runtime = getattr(request.app.state, "runtime", None)
    if runtime is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Runtime is not initialized yet.",
        )
    return runtime
