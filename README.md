# BrainrotVision

BrainrotVision is a local-first computer vision project for exploratory analysis, clustering, similarity retrieval, and optional classification over the Italian brainrot image dataset from Kaggle [`bubblepw/italian-brainrot-images`](https://www.kaggle.com/datasets/bubblepw/italian-brainrot-images).

The repo contains:

- a shared Python package for data ingestion, EDA, embeddings, clustering, and inference
- a FastAPI backend for local analysis APIs
- a Flutter app for one-tap sample demos, image upload, results, and dataset insights
- documentation, automation, and validation scripts

## Repository Layout

```text
.
├── backend/
├── data/
├── docs/
├── flutter_app/
├── ml/
├── notebooks/
├── scripts/
├── src/brainrotvision/
└── tests/
```

## Local Setup

```bash
make setup
```

This project uses a local `.venv` because the host Arch Linux Python environment is externally managed.

## Dataset Workflow

The repository now uses a repo-local raw dataset layout by default:

- raw zip: `data/raw/brainrot_dataset.zip`
- extracted images: `data/raw/brainrot_dataset/`
- processed metadata and reports: `data/processed/`
- thumbnails: `data/thumbnails/`
- ML artifacts: `ml/artifacts/`

On this machine, the source archive was copied from:

```text
/home/gablegoob/Downloads/brainrot_dataset.zip
```

To place a fresh local copy into the repo and extract it:

```bash
cp /path/to/brainrot_dataset.zip data/raw/brainrot_dataset.zip
make data
```

`make data` now prefers the repo-local zip automatically. If the zip is absent, it falls back to Kaggle download using the dataset slug `bubblepw/italian-brainrot-images`.

## Build the Pipeline

```bash
make metadata
make artifacts
make eda
```

This order ensures the embedding projection plot is available during the EDA pass.

To fully regenerate processed outputs from scratch:

```bash
rm -rf data/raw/brainrot_dataset data/thumbnails/* data/processed/* ml/artifacts/*
cp /path/to/brainrot_dataset.zip data/raw/brainrot_dataset.zip
make data
make metadata
make artifacts
make eda
```

Expected generated artifacts include:

- `data/processed/metadata.csv`
- `data/processed/metadata.parquet`
- `data/processed/dataset_stats.json`
- `data/processed/reports/exact_duplicates.csv`
- `data/processed/reports/near_duplicates.csv`
- `data/processed/reports/eda_summary.md`
- `data/processed/plots/*.png`
- `ml/artifacts/embeddings.npy`
- `ml/artifacts/nearest_neighbors.joblib`
- `ml/artifacts/kmeans.joblib`
- `ml/artifacts/dbscan.joblib`
- `ml/artifacts/classifier.joblib`
- `ml/artifacts/embedding_projection.csv`
- `ml/artifacts/manifest.json`

If you want to point the pipeline at a different data directory for testing or smoke validation, override `DATA_DIR` and `ARTIFACTS_DIR`:

```bash
DATA_DIR=/tmp/brainrotvision-smoke ARTIFACTS_DIR=/tmp/brainrotvision-smoke/artifacts .venv/bin/python -m brainrotvision.cli metadata
DATA_DIR=/tmp/brainrotvision-smoke ARTIFACTS_DIR=/tmp/brainrotvision-smoke/artifacts .venv/bin/python -m brainrotvision.cli eda
DATA_DIR=/tmp/brainrotvision-smoke ARTIFACTS_DIR=/tmp/brainrotvision-smoke/artifacts .venv/bin/python -m brainrotvision.cli artifacts
```

## Run the Backend

```bash
make backend
```

The backend serves:

- `GET /health`
- `GET /stats`
- `GET /samples`
- `POST /analyze`
- `POST /analyze/sample`
- `POST /similar`
- `POST /predict` when a classifier artifact exists

If port `8000` is already busy on your machine, run:

```bash
BACKEND_PORT=8010 .venv/bin/uvicorn backend.app.main:app --host 127.0.0.1 --port 8010
```

## Run the Flutter App

Linux desktop is the primary verified target in this environment:

```bash
make flutter
```

The home screen now supports immediate dataset-backed demo actions:

- `Use Random Dataset Image`
- `Try Sample Demo`
- clickable sample thumbnails that run live backend analysis
- `View Example Result` for a one-click results flow

Static checks:

```bash
make flutter-analyze
make flutter-test
```

## Android SDK Bootstrap

Flutter is already installed on this machine, but the Android SDK is not yet configured. A user-local bootstrap script is included:

```bash
make android-sdk
```

This script completed successfully on the current Arch Linux machine and configured:

- Android SDK at `~/Android/Sdk`
- Platform `android-37.0`
- Build-tools `37.0.0`
- accepted Android licenses

`flutter doctor -v` now reports the Android toolchain as available.

## Validation

```bash
make validate
```

Additional commands used during implementation:

```bash
.venv/bin/pytest
cd flutter_app && flutter analyze
cd flutter_app && flutter test
cd flutter_app && flutter build linux
make data
BACKEND_PORT=8010 .venv/bin/uvicorn backend.app.main:app --host 127.0.0.1 --port 8010
```

Validation results on this machine:

- Python tests passed.
- `flutter analyze` passed.
- `flutter test` passed.
- `flutter build linux` succeeded.
- The repo-local dataset zip was copied into `data/raw/brainrot_dataset.zip`, extracted into `data/raw/brainrot_dataset/`, and processed successfully.
- The real dataset produced `1000` valid images across `5` balanced classes.
- FastAPI responded successfully with real dataset artifacts on `/health`, `/stats`, `/samples`, `/analyze`, `/similar`, and `/predict`.
- The dataset-backed demo route `/analyze/sample` returned real classification, cluster, and similarity results from indexed samples.
- The classifier trained cleanly on the real dataset and reached `0.8000` accuracy with `0.7993` macro-F1.
- `flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:8012` launched successfully against the real dataset-backed backend.
- Android SDK bootstrap succeeded, but `flutter build apk --debug` is still blocked by the read-only Arch-packaged Flutter SDK attempting to write Kotlin session data inside `/usr/lib/flutter`.

## Git Workflow

This project is initialized as a git repository with phase-based commits. The implementation flow also prepares and pushes to a GitHub remote when authentication and remote creation succeed.
