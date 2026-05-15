#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
APP="$1"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ENTITLEMENTS="$SCRIPT_DIR/entitlements.plist"

if [ ! -d "$APP" ]; then
  echo "App not found: $APP" >&2
  exit 1
fi

if ! command -v codesign >/dev/null 2>&1; then
  echo "codesign not found" >&2
  exit 1
fi

codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGN_IDENTITY" \
  "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"

if [ -d "$DIST" ]; then
  echo "$APP"
fi
