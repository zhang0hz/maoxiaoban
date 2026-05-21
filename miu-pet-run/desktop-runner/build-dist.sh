#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER_DIR="$ROOT/miu-pet-run/desktop-runner"
DIST="$ROOT/miu-pet-run/dist"
PRODUCT_NAME="猫小伴"

if [ -f "$RUNNER_DIR/release.env" ]; then
  # shellcheck source=/dev/null
  source "$RUNNER_DIR/release.env"
fi

"$RUNNER_DIR/build-app.sh" >/dev/null

rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$RUNNER_DIR/$PRODUCT_NAME.app" "$DIST/$PRODUCT_NAME.app"

SIGN_IDENTITY="${SIGN_IDENTITY:--}"
"$RUNNER_DIR/sign-release.sh" "$DIST/$PRODUCT_NAME.app" >/dev/null

(
  cd "$DIST"
  ditto -c -k --keepParent "$PRODUCT_NAME.app" "$PRODUCT_NAME.zip"
)

echo "$DIST/$PRODUCT_NAME.app"
echo "$DIST/$PRODUCT_NAME.zip"
