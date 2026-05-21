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
require_file "$RUNNER/V1.0.2_INTERNAL_PATCH.md"
require_file "$RUNNER/V1.2_SETTINGS_EXPERIENCE.md"
require_file "$RUNNER/V1.3_DISTRIBUTION_READY.md"
require_file "$RUNNER/GITHUB_RELEASE_DRAFT.md"
require_file "$ACTIONS/ASSET_NAMING.md"
require_file "$ACTIONS/formal-assets.json"

require_text "$RUNNER/MiuRunner+Behavior.swift" "func prepareReminderMotion"
require_text "$RUNNER/MiuRunner+Behavior.swift" "func transitionAction"
require_text "$RUNNER/MiuRunner+Behavior.swift" "func subtleCompanionAction"
require_text "$RUNNER/MiuRunner+Behavior.swift" "minimumSeconds: 12.0"
require_text "$RUNNER/MiuRunner+Behavior.swift" "idleSeconds > 900"
require_text "$RUNNER/MiuRunner+Behavior.swift" "idleSeconds < 240"
require_text "$RUNNER/MiuRunner+Behavior.swift" "timeIntervalSince(lastMicroExpressionAt) > 48"

require_text "$RUNNER/MiuRunner+Settings.swift" "func validateReminderEdits"
require_text "$RUNNER/MiuRunner+Settings.swift" "func makeVersionInfoView"
require_text "$RUNNER/MiuRunner+Settings.swift" "恢复推荐设置"
require_text "$RUNNER/MiuRunner+Commands.swift" "func resetRecommendedSettings"
require_text "$RUNNER/MiuRunner+Settings.swift" "CFBundleShortVersionString"
require_text "$RUNNER/MiuRunner+Settings.swift" "window.minSize"
require_text "$RUNNER/MiuRunner+Settings.swift" ".resizable"
require_text "$RUNNER/MiuRunner+Settings.swift" "高级"

require_text "$ACTIONS/action-manifest.json" "\"status\": \"formal\""
require_text "$ACTIONS/formal-assets.json" "\"runtimeUse\""
require_text "$RUNNER/RELEASE_CHECKLIST.md" "Developer ID release handoff"
require_text "$RUNNER/RELEASE_CHECKLIST.md" "Roadmap static checks included"
require_text "$RUNNER/INSTALL.md" "Gatekeeper"
require_text "$RUNNER/UNINSTALL.md" "Launch at Login"
require_text "$RUNNER/GITHUB_RELEASE_DRAFT.md" "git push origin --tags"

echo "猫小伴 roadmap static checks passed"
