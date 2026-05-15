#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PRODUCT_NAME="猫小伴"
DIST_APP="$ROOT/miu-pet-run/dist/$PRODUCT_NAME.app"

if [ ! -d "$DIST_APP" ]; then
  "$ROOT/miu-pet-run/desktop-runner/build-dist.sh" >/dev/null
fi

rm -rf "/Applications/$PRODUCT_NAME.app" "/Applications/Miu.app"
cp -R "$DIST_APP" "/Applications/$PRODUCT_NAME.app"
open "/Applications/$PRODUCT_NAME.app"
echo "/Applications/$PRODUCT_NAME.app"
