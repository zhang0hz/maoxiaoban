#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUNNER_DIR="$ROOT/miu-pet-run/desktop-runner"
APP="${1:-$RUNNER_DIR/猫小伴.app}"

"$RUNNER_DIR/build-app.sh" >/dev/null
node "$ROOT/miu-pet-run/behavior-layer/test/behavior.test.mjs"
bash "$RUNNER_DIR/v1.0.1-static-test.sh"
python3 "$RUNNER_DIR/color_audit.py" --frames-root "$APP/Contents/Resources/frames"
bash -n "$RUNNER_DIR"/*.sh
PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-/tmp/maoxiaoban-pycache}" python3 -m py_compile "$RUNNER_DIR"/*.py

plutil -lint "$APP/Contents/Info.plist"
test -x "$APP/Contents/MacOS/MiuDesktopRunner"
test -d "$APP/Contents/Resources/frames/loaf"
test -f "$APP/Contents/Resources/AppIcon.icns"
test -f "$APP/Contents/Resources/StatusIcon.png"

echo "猫小伴 smoke test passed: $APP"
