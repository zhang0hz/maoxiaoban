#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
APP="${1:-$DIST/$PRODUCT_NAME.app}"

if [ ! -d "$APP" ]; then
  echo "App not found: $APP" >&2
  exit 1
fi

plutil -lint "$APP/Contents/Info.plist"
codesign --verify --deep --strict --verbose=2 "$APP"
SIGN_INFO="$(codesign -dv --verbose=4 "$APP" 2>&1)"
printf '%s\n' "$SIGN_INFO" | sed -n '1,80p'

if printf '%s\n' "$SIGN_INFO" | grep -q "Signature=adhoc"; then
  echo "Ad-hoc signature detected; skipping Gatekeeper and stapler checks."
  echo "$APP"
  exit 0
fi

if command -v spctl >/dev/null 2>&1; then
  spctl --assess --type execute --verbose=4 "$APP" || true
fi

if command -v xcrun >/dev/null 2>&1; then
  xcrun stapler validate "$APP" || true
fi

echo "$APP"
