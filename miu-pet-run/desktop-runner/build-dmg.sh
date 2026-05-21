#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
APP="$DIST/$PRODUCT_NAME.app"
STAGING="$DIST/dmg-staging"
DMG="$DIST/$PRODUCT_NAME.dmg"

if [ -f "$SCRIPT_DIR/release.env" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/release.env"
  APP="$DIST/$PRODUCT_NAME.app"
  STAGING="$DIST/dmg-staging"
  DMG="$DIST/$PRODUCT_NAME.dmg"
fi

if [ ! -d "$APP" ]; then
  "$SCRIPT_DIR/build-dist.sh" >/dev/null
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil not found" >&2
  exit 1
fi

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/$PRODUCT_NAME.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "$PRODUCT_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

rm -rf "$STAGING"
hdiutil verify "$DMG" >/dev/null

echo "$DMG"
