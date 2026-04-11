SHELL := /usr/bin/env bash
VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
FLUTTER := flutter
API_BASE_URL ?= http://127.0.0.1:8000

.PHONY: help setup data metadata eda artifacts backend flutter flutter-analyze flutter-test validate android-sdk clean

help:
	@printf "Available targets:\n"
	@printf "  make setup            Create .venv and install Python dependencies\n"
	@printf "  make data             Download the Kaggle dataset when auth is available\n"
	@printf "  make metadata         Extract metadata and thumbnails\n"
	@printf "  make eda              Generate EDA plots and reports\n"
	@printf "  make artifacts        Build embeddings, search index, clusters, and optional classifier\n"
	@printf "  make backend          Run the FastAPI backend locally\n"
	@printf "  make flutter          Run the Flutter app on Linux desktop\n"
	@printf "  make flutter-analyze  Run Flutter static analysis\n"
	@printf "  make flutter-test     Run Flutter tests\n"
	@printf "  make validate         Run Python and Flutter validation steps\n"
	@printf "  make android-sdk      Bootstrap a user-local Android SDK\n"

setup:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip setuptools wheel
	$(PIP) install --index-url https://download.pytorch.org/whl/cpu torch torchvision
	$(PIP) install -e ".[dev]"

data:
	$(PYTHON) -m brainrotvision.cli download

metadata:
	$(PYTHON) -m brainrotvision.cli metadata

eda:
	$(PYTHON) -m brainrotvision.cli eda

artifacts:
	$(PYTHON) -m brainrotvision.cli artifacts

backend:
	$(VENV)/bin/uvicorn backend.app.main:app --host $${BACKEND_HOST:-0.0.0.0} --port $${BACKEND_PORT:-8000} --reload

flutter:
	cd flutter_app && $(FLUTTER) pub get && $(FLUTTER) run -d linux --dart-define=API_BASE_URL=$(API_BASE_URL)

flutter-analyze:
	cd flutter_app && $(FLUTTER) pub get && $(FLUTTER) analyze

flutter-test:
	cd flutter_app && $(FLUTTER) pub get && $(FLUTTER) test

validate:
	$(VENV)/bin/pytest
	cd flutter_app && $(FLUTTER) analyze && $(FLUTTER) test

android-sdk:
	bash scripts/bootstrap_android_sdk.sh

clean:
	rm -rf $(VENV) .pytest_cache .coverage htmlcov
