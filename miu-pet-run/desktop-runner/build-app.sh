#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER_DIR="$ROOT/miu-pet-run/desktop-runner"
PRODUCT_NAME="猫小伴"
APP="$RUNNER_DIR/$PRODUCT_NAME.app"
MODULE_CACHE="$RUNNER_DIR/module-cache"

mkdir -p "$MODULE_CACHE"
"$RUNNER_DIR/build-icon.sh" >/dev/null
SWIFT_SOURCES=()
while IFS= read -r source; do
  SWIFT_SOURCES+=("$source")
done < <(find "$RUNNER_DIR" -maxdepth 1 -name "*.swift" -print | sort)

CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" swiftc -O -framework AppKit -framework CoreGraphics -framework ServiceManagement \
  "${SWIFT_SOURCES[@]}" \
  -o "$RUNNER_DIR/MiuDesktopRunner"

rm -rf "$APP" "$RUNNER_DIR/Miu.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$RUNNER_DIR/Info.plist" "$APP/Contents/Info.plist"
cp "$RUNNER_DIR/MiuDesktopRunner" "$APP/Contents/MacOS/MiuDesktopRunner"
cp -R "$ROOT/miu-pet-run/phase1-actions/frames" "$APP/Contents/Resources/frames"
cp "$RUNNER_DIR/Assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$RUNNER_DIR/Assets/StatusIcon.png" "$APP/Contents/Resources/StatusIcon.png"
cp "$RUNNER_DIR/Assets/StatusIcon@2x.png" "$APP/Contents/Resources/StatusIcon@2x.png"

echo "$APP"
