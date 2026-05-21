#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/release.env" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/release.env"
fi

"$SCRIPT_DIR/build-dist.sh"
OPEN_AFTER_INSTALL=0 "$SCRIPT_DIR/install-to-applications.sh"
"$SCRIPT_DIR/build-dmg.sh"

if [ "${NOTARIZE:-0}" = "1" ]; then
  PRODUCT_NAME="${PRODUCT_NAME:-猫小伴}"
  ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  "$SCRIPT_DIR/notarize-release.sh" "$ROOT/miu-pet-run/dist/$PRODUCT_NAME.dmg" "$ROOT/miu-pet-run/dist/$PRODUCT_NAME.app"
fi
