#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER_DIR="$ROOT/miu-pet-run/desktop-runner"
PRODUCT_NAME="猫小伴"
DIST_APP="$ROOT/miu-pet-run/dist/$PRODUCT_NAME.app"

if [ -f "$RUNNER_DIR/release.env" ]; then
  # shellcheck source=/dev/null
  source "$RUNNER_DIR/release.env"
  DIST_APP="$ROOT/miu-pet-run/dist/$PRODUCT_NAME.app"
fi

if [ ! -d "$DIST_APP" ]; then
  "$RUNNER_DIR/build-dist.sh" >/dev/null
fi

rm -rf "/Applications/$PRODUCT_NAME.app" "/Applications/Miu.app"
cp -R "$DIST_APP" "/Applications/$PRODUCT_NAME.app"
if [ "${OPEN_AFTER_INSTALL:-1}" = "1" ]; then
  open "/Applications/$PRODUCT_NAME.app"
fi
echo "/Applications/$PRODUCT_NAME.app"
