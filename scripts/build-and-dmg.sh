#!/usr/bin/env bash
# NotchOz — Builds Release and creates a DMG.
# Signing must be configured in Xcode (Sign to Run Locally or Developer ID).
# Usage: ./scripts/build-and-dmg.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="NotchWidgets"
SCHEME="NotchOz"
APP_NAME="NotchOz"
CONFIG="Release"
DERIVED_PATH="$PROJECT_ROOT/build"
DMG_DIR="$PROJECT_ROOT/dist"
DMG_NAME="NotchOz.dmg"

cd "$PROJECT_ROOT"

if ! xcodebuild -version &>/dev/null; then
    echo "Error: xcodebuild requires Xcode (not just Command Line Tools)."
    echo "Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo "Cleaning and building Release..."
xcodebuild \
  -project "$PROJECT_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_PATH" \
  clean build

APP_PATH="$DERIVED_PATH/Build/Products/$CONFIG/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: $APP_PATH not found." >&2
  exit 1
fi

echo "Preparing DMG contents..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"

echo "Creating DMG..."
rm -f "$PROJECT_ROOT/$DMG_NAME"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$PROJECT_ROOT/$DMG_NAME"

rm -rf "$DMG_DIR"
echo "Done. DMG created: $PROJECT_ROOT/$DMG_NAME"
