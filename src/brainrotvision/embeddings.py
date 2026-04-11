from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from sklearn.preprocessing import normalize

from .utils import LOGGER


def _resolve_device(requested: str) -> str:
    import torch

    if requested == "auto":
        return "cuda" if torch.cuda.is_available() else "cpu"
    return requested


class EmbeddingExtractor:
    def __init__(self, device: str = "cpu") -> None:
        try:
            import torch
            from torchvision import models
        except ModuleNotFoundError as exc:
            raise RuntimeError(
                "Torch and torchvision are required for embeddings. Run `make setup` first."
            ) from exc

        resolved_device = _resolve_device(device)
        weights = models.ResNet50_Weights.DEFAULT
        backbone = models.resnet50(weights=weights)
        feature_extractor = torch.nn.Sequential(*list(backbone.children())[:-1])
        feature_extractor.eval()
        feature_extractor.to(resolved_device)

        self._torch = torch
        self._model = feature_extractor
        self._transform = weights.transforms()
        self._device = resolved_device
        LOGGER.info("Loaded ResNet50 embedding model on device=%s", resolved_device)

    @property
    def device(self) -> str:
        return self._device

    def embed_pil_image(self, image: Image.Image) -> np.ndarray:
        rgb_image = image.convert("RGB")
        tensor = self._transform(rgb_image).unsqueeze(0).to(self._device)
        with self._torch.inference_mode():
            embedding = self._model(tensor).flatten(start_dim=1).cpu().numpy()
        return embedding[0]

    def embed_paths(self, image_paths: list[Path], batch_size: int = 16) -> np.ndarray:
        embeddings: list[np.ndarray] = []
        for start in range(0, len(image_paths), batch_size):
            batch_paths = image_paths[start : start + batch_size]
            tensors = []
            for path in batch_paths:
                with Image.open(path) as image:
                    tensors.append(self._transform(image.convert("RGB")))
            if not tensors:
                continue
            batch = self._torch.stack(tensors).to(self._device)
            with self._torch.inference_mode():
                outputs = self._model(batch).flatten(start_dim=1).cpu().numpy()
            embeddings.append(outputs)
        if not embeddings:
            return np.empty((0, 2048), dtype=np.float32)
        return np.concatenate(embeddings, axis=0).astype(np.float32)


def normalize_embeddings(embeddings: np.ndarray) -> np.ndarray:
    if embeddings.size == 0:
        return embeddings
    return normalize(embeddings)
