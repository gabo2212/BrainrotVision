# BrainrotVision Architecture

## Overview

BrainrotVision is organized as a local-first, three-layer system:

1. `src/brainrotvision/`
   Shared Python package for data ingestion, metadata extraction, EDA, embeddings, clustering, similarity search, and artifact loading.
2. `backend/`
   FastAPI app that loads generated artifacts once at startup and exposes inference and insights routes for the mobile app.
3. `flutter_app/`
   Flutter client for image selection, preview, analysis requests, and dataset insights.

## Data and ML Decisions

- The primary product is embeddings + similarity + clustering because the dataset may not have reliable labels.
- The default visual backbone is a pretrained `torchvision` ResNet50 feature extractor.
- Similarity search uses cosine-based `NearestNeighbors`.
- Clustering uses both KMeans and DBSCAN, with KMeans providing deployable cluster assignment for new uploads.
- Classification is optional and only enabled when inferred folder labels are clean enough to train and evaluate a simple model responsibly.

## Backend Decisions

- The backend reads generated metadata and artifact files from disk instead of retraining on startup.
- Uploaded images go through the same preprocessing and embedding pipeline as dataset images.
- Sample and thumbnail paths are served as static files so the Flutter app can render dataset examples directly.
- When data or artifacts are missing, the backend starts in a degraded mode so `GET /health` and `GET /stats` still respond with a clear readiness message instead of crashing on startup.

## Flutter Decisions

- `provider` is used for simple app-wide state.
- `http` is used for backend communication.
- `image_picker` handles gallery and camera flows.
- Linux desktop is the primary validated target in the current environment; Android is best-effort and depends on local SDK bootstrap.
