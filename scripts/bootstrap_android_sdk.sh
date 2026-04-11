#!/usr/bin/env bash
set -euo pipefail

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools/latest"
TMP_DIR="$(mktemp -d)"
ZIP_URL="${ANDROID_CMDLINE_TOOLS_ZIP_URL:-https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

if [[ ! -x "$CMDLINE_TOOLS_DIR/bin/sdkmanager" ]]; then
  echo "Downloading Android command-line tools to $ANDROID_SDK_ROOT"
  curl -L "$ZIP_URL" -o "$TMP_DIR/commandlinetools.zip"
  unzip -q "$TMP_DIR/commandlinetools.zip" -d "$TMP_DIR/unpacked"
  rm -rf "$CMDLINE_TOOLS_DIR"
  mkdir -p "$CMDLINE_TOOLS_DIR"
  cp -R "$TMP_DIR/unpacked/cmdline-tools/." "$CMDLINE_TOOLS_DIR/"
fi

SDKMANAGER="$CMDLINE_TOOLS_DIR/bin/sdkmanager"
export ANDROID_SDK_ROOT
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$CMDLINE_TOOLS_DIR/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

PACKAGE_LIST="$("$SDKMANAGER" --list)"
LATEST_PLATFORM="$(
  printf '%s\n' "$PACKAGE_LIST" \
    | awk '/^  platforms;android-[0-9]+(\.[0-9]+)?[[:space:]]+\|/ {print $1}' \
    | sort -V \
    | tail -1
)"
LATEST_BUILD_TOOLS="$(
  printf '%s\n' "$PACKAGE_LIST" \
    | awk '/^  build-tools;[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+\|/ {print $1}' \
    | sort -V \
    | tail -1
)"

if [[ -z "$LATEST_PLATFORM" || -z "$LATEST_BUILD_TOOLS" ]]; then
  echo "Unable to determine the latest Android platform/build-tools package."
  exit 1
fi

set +o pipefail
yes | "$SDKMANAGER" --licenses >/dev/null
set -o pipefail
"$SDKMANAGER" "platform-tools" "$LATEST_PLATFORM" "$LATEST_BUILD_TOOLS"
flutter config --android-sdk "$ANDROID_SDK_ROOT"
flutter doctor -v
