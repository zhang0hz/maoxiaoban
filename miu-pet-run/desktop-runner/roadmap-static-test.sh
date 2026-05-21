#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT/miu-pet-run/desktop-runner"
ACTIONS="$ROOT/miu-pet-run/phase1-actions"

require_file() {
  test -f "$1" || {
    echo "Missing file: $1" >&2
    exit 1
  }
}

require_text() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "Missing expected text in $file: $pattern" >&2
    exit 1
  fi
}

require_file "$RUNNER/V0.19_BEHAVIOR_TUNING.md"
require_file "$RUNNER/V0.20_VISUAL_MOTION.md"
require_file "$RUNNER/V1.2_SETTINGS_EXPERIENCE.md"
require_file "$RUNNER/V1.3_DISTRIBUTION_READY.md"
require_file "$ACTIONS/ASSET_NAMING.md"
require_file "$ACTIONS/formal-assets.json"

require_text "$RUNNER/MiuRunner+Behavior.swift" "func prepareReminderMotion"
require_text "$RUNNER/MiuRunner+Behavior.swift" "func transitionAction"
require_text "$RUNNER/MiuRunner+Behavior.swift" "func subtleCompanionAction"
require_text "$RUNNER/MiuRunner+Behavior.swift" "minimumSeconds: 9.0"
require_text "$RUNNER/MiuRunner+Behavior.swift" "idleSeconds > 480"
require_text "$RUNNER/MiuRunner+Behavior.swift" "idleSeconds > 180"

require_text "$RUNNER/MiuRunner+Settings.swift" "func validateReminderEdits"
require_text "$RUNNER/MiuRunner+Settings.swift" "window.minSize"
require_text "$RUNNER/MiuRunner+Settings.swift" ".resizable"
require_text "$RUNNER/MiuRunner+Settings.swift" "高级"

require_text "$ACTIONS/action-manifest.json" "\"status\": \"formal\""
require_text "$ACTIONS/formal-assets.json" "\"runtimeUse\""
require_text "$RUNNER/RELEASE_CHECKLIST.md" "Developer ID release handoff"
require_text "$RUNNER/INSTALL.md" "Gatekeeper"
require_text "$RUNNER/UNINSTALL.md" "Launch at Login"

echo "猫小伴 roadmap static checks passed"
