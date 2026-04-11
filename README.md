# BrainrotVision

BrainrotVision is a local-first computer vision project for exploratory analysis, clustering, similarity retrieval, and optional classification over the Kaggle dataset [`bubblepw/italian-brainrot-images`](https://www.kaggle.com/datasets/bubblepw/italian-brainrot-images).

The repo contains:

- a shared Python package for data ingestion, EDA, embeddings, clustering, and inference
- a FastAPI backend for local analysis APIs
- a Flutter app for image upload, results, and dataset insights
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

### Dataset Download

If Kaggle authentication is already configured in `~/.kaggle/kaggle.json`, run:

```bash
make data
```

If Kaggle auth is not configured yet, the fastest one-command path is:

```bash
KAGGLE_USERNAME=your_username KAGGLE_KEY=your_key make data
```

The downloader uses the dataset slug `bubblepw/italian-brainrot-images` and extracts into `data/raw/`.

## Build the Pipeline

```bash
make metadata
make eda
make artifacts
```

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
- FastAPI responded successfully in degraded mode without the Kaggle dataset.
- A temporary smoke dataset successfully exercised metadata extraction, EDA generation, artifact building, and `POST /analyze`.
- Android SDK bootstrap succeeded, but `flutter build apk --debug` is still blocked by the read-only Arch-packaged Flutter SDK attempting to write Kotlin session data inside `/usr/lib/flutter`.

## Git Workflow

This project is initialized as a git repository with phase-based commits. The implementation flow also prepares and pushes to a GitHub remote when authentication and remote creation succeed.
