from __future__ import annotations

import argparse

from .artifacts import build_artifacts
from .config import get_settings
from .dataset import build_metadata, download_dataset
from .eda import generate_eda
from .utils import configure_logging


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="BrainrotVision CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("download", help="Download the Kaggle dataset")
    subparsers.add_parser("metadata", help="Build metadata and thumbnails")
    subparsers.add_parser("eda", help="Generate EDA plots and reports")
    subparsers.add_parser("artifacts", help="Generate embeddings and ML artifacts")
    return parser


def main() -> None:
    configure_logging()
    parser = build_parser()
    args = parser.parse_args()
    settings = get_settings()

    if args.command == "download":
        download_dataset(settings)
    elif args.command == "metadata":
        build_metadata(settings)
    elif args.command == "eda":
        generate_eda(settings)
    elif args.command == "artifacts":
        build_artifacts(settings)
    else:
        parser.error(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
