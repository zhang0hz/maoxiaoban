#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
NOTARY_PROFILE="${NOTARY_PROFILE:-maoxiaoban-notary}"
ARTIFACT="$1"
APP="${2:-$DIST/$PRODUCT_NAME.app}"

if [ ! -f "$ARTIFACT" ]; then
  echo "Artifact not found: $ARTIFACT" >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found" >&2
  exit 1
fi

xcrun notarytool submit "$ARTIFACT" --keychain-profile "$NOTARY_PROFILE" --wait

if [ -d "$APP" ]; then
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
fi

if [[ "$ARTIFACT" == *.dmg ]]; then
  xcrun stapler staple "$ARTIFACT"
  xcrun stapler validate "$ARTIFACT"
fi

echo "$ARTIFACT"
