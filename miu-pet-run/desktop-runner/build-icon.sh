#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$SCRIPT_DIR/Assets"
ICONSET="$ASSETS/AppIcon.iconset"
ICNS="$ASSETS/AppIcon.icns"

python3 "$SCRIPT_DIR/make-app-icon.py" >/dev/null
test -d "$ICONSET"
test -f "$ICNS"

echo "$ICNS"
