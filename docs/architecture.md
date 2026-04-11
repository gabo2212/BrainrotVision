# BrainrotVision Architecture

## Overview

BrainrotVision is organized as a local-first, three-layer system:

1. `src/brainrotvision/`
   Shared Python package for data ingestion, metadata extraction, EDA, embeddings, clustering, similarity search, and artifact loading.
2. `backend/`
   FastAPI app that loads generated artifacts once at startup and exposes inference and insights routes for the mobile app.
3. `flutter_app/`
   Flutter client for image selection, preview, analysis requests, and dataset insights.

## Real Dataset Layout

The current repository uses a repo-local raw dataset workflow:

- source archive: `data/raw/brainrot_dataset.zip`
- extracted dataset root: `data/raw/brainrot_dataset/`
- class folders under the extracted root:
  - `ballerina_cappuccina`
  - `bombardino_crocodilo`
  - `cappuccino_assassino`
  - `tralalero_tralala`
  - `tung_tung_sahur`

This real dataset is balanced at 200 images per class, which is strong enough to enable the optional classifier on top of embeddings rather than leaving the system retrieval-only.

## Data and ML Decisions

- The primary product is embeddings + similarity + clustering because the dataset may not have reliable labels.
- The default visual backbone is a pretrained `torchvision` ResNet50 feature extractor.
- Similarity search uses cosine-based `NearestNeighbors`.
- Clustering uses both KMeans and DBSCAN, with KMeans providing deployable cluster assignment for new uploads.
- Classification is optional and only enabled when inferred folder labels are clean enough to train and evaluate a simple model responsibly.
- With the integrated local dataset, folder labels are clean and balanced enough to train a lightweight classifier; the current embedding-based logistic regression model is active.

## Backend Decisions

- The backend reads generated metadata and artifact files from disk instead of retraining on startup.
- Uploaded images go through the same preprocessing and embedding pipeline as dataset images.
- The analysis response is recognition-first: it returns a known-class identity prediction, human-readable class labels, top-3 probabilities, neighbor agreement, cluster alignment, and softened wording for low-confidence matches.
- Sample and thumbnail paths are served as static files so the Flutter app can render dataset examples directly.
- When data or artifacts are missing, the backend starts in a degraded mode so `GET /health` and `GET /stats` still respond with a clear readiness message instead of crashing on startup.
- With the current real dataset artifacts present, the backend now serves a fully ready mode including `POST /predict`.

## Flutter Decisions

- `provider` is used for simple app-wide state.
- `http` is used for backend communication.
- `image_picker` handles gallery and camera flows.
- The home screen also exposes dataset-native demo actions so first-time users can trigger real analysis from indexed sample images without manually uploading a file.
- Linux desktop is the primary validated target in the current environment; Android is best-effort and depends on local SDK bootstrap.
