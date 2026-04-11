from __future__ import annotations

from fastapi.testclient import TestClient

from backend.app.main import create_app


class StubRuntime:
    ready = True
    classifier_available = True

    def health(self):
        return {"ready": True, "samples_indexed": 3, "classifier_available": True}

    def get_stats(self):
        return {"total_images": 3, "artifact_ready": True}

    def get_samples(self, limit: int = 12):
        return [
            {
                "filename": "sample.jpg",
                "label": "alpha",
                "kmeans_cluster": 0,
                "dbscan_cluster": 0,
                "width": 100,
                "height": 100,
                "format": "JPEG",
                "distance": 0.12,
                "raw_relative_path": "sample.jpg",
                "thumbnail_path": "sample-thumb.jpg",
                "raw_url": "/raw/sample.jpg",
                "thumbnail_url": "/thumbnails/sample-thumb.jpg",
            }
        ][:limit]

    def analyze_bytes(self, content: bytes, filename: str | None = None):
        return {
            "filename": filename or "upload.jpg",
            "width": 64,
            "height": 64,
            "format": "JPEG",
            "brightness": 120.5,
            "contrast": 33.1,
            "cluster_id": 1,
            "classification": {"label": "alpha", "confidence": 0.88},
            "similar_images": self.get_samples(),
            "upload_sha256": "deadbeef",
        }

    def analyze_sample(self, raw_relative_path: str):
        return {
            "filename": raw_relative_path.rsplit("/", maxsplit=1)[-1],
            "width": 64,
            "height": 64,
            "format": "JPEG",
            "brightness": 120.5,
            "contrast": 33.1,
            "cluster_id": 1,
            "classification": {"label": "alpha", "confidence": 0.88},
            "similar_images": self.get_samples(),
            "upload_sha256": "samplehash",
        }

    def similar_bytes(self, content: bytes, filename: str | None = None):
        return {
            "filename": filename or "upload.jpg",
            "cluster_id": 1,
            "similar_images": self.get_samples(),
        }


def test_health_route():
    client = TestClient(create_app(runtime=StubRuntime()))
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["ready"] is True


def test_stats_route():
    client = TestClient(create_app(runtime=StubRuntime()))
    response = client.get("/stats")
    assert response.status_code == 200
    assert response.json()["payload"]["total_images"] == 3


def test_analyze_route():
    client = TestClient(create_app(runtime=StubRuntime()))
    response = client.post(
        "/analyze",
        files={"file": ("upload.jpg", b"fake-image", "image/jpeg")},
    )
    assert response.status_code == 200
    assert response.json()["classification"]["label"] == "alpha"


def test_analyze_sample_route():
    client = TestClient(create_app(runtime=StubRuntime()))
    response = client.post(
        "/analyze/sample",
        json={"raw_relative_path": "brainrot_dataset/alpha/sample.jpg"},
    )
    assert response.status_code == 200
    assert response.json()["filename"] == "sample.jpg"
    assert response.json()["upload_sha256"] == "samplehash"


def test_predict_route():
    client = TestClient(create_app(runtime=StubRuntime()))
    response = client.post(
        "/predict",
        files={"file": ("upload.jpg", b"fake-image", "image/jpeg")},
    )
    assert response.status_code == 200
    assert response.json()["label"] == "alpha"
