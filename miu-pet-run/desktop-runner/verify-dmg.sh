#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
DMG="${1:-$DIST/$PRODUCT_NAME.dmg}"

if [ ! -f "$DMG" ]; then
  echo "DMG not found: $DMG" >&2
  exit 1
fi

hdiutil verify "$DMG"
hdiutil imageinfo "$DMG" | sed -n '1,80p'

MOUNT_ROOT="$(mktemp -d /tmp/maoxiaoban-dmg.XXXXXX)"
ATTACH_OUTPUT="$(hdiutil attach "$DMG" -readonly -nobrowse -mountroot "$MOUNT_ROOT")"
MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk -F'\t' 'NF > 2 {print $3}' | tail -n 1)"

if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
  echo "Failed to mount DMG" >&2
  printf '%s\n' "$ATTACH_OUTPUT" >&2
  exit 1
fi

test -d "$MOUNT_POINT/$PRODUCT_NAME.app"
test -L "$MOUNT_POINT/Applications"

hdiutil detach "$MOUNT_POINT" >/dev/null
rmdir "$MOUNT_ROOT" 2>/dev/null || true

echo "$DMG"
