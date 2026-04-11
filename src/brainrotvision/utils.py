from __future__ import annotations

import json
import logging
import random
from pathlib import Path
from typing import Any

import numpy as np


LOGGER = logging.getLogger("brainrotvision")


def configure_logging(level: int = logging.INFO) -> None:
    logging.basicConfig(
        level=level,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    )


def ensure_directories(paths: list[Path]) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def set_random_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
