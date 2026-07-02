#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT/miu-pet-run/desktop-runner"

require_text() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "Missing expected text in $file: $pattern" >&2
    exit 1
  fi
}

reject_text() {
  local file="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    echo "Unexpected text in $file: $pattern" >&2
    exit 1
  fi
}

require_text "$RUNNER/PetView.swift" "private var alphaBitmap"
require_text "$RUNNER/PetView.swift" "rebuildAlphaBitmap"
require_text "$RUNNER/PetView.swift" "window?.alphaValue"
require_text "$RUNNER/PetView.swift" "viewDidMoveToWindow"

require_text "$RUNNER/MiuRunner+Behavior.swift" "setPetWindowInteractive(false)"
require_text "$RUNNER/MiuRunner+Behavior.swift" "setPetWindowInteractive(true)"
require_text "$RUNNER/MiuRunner+Placement.swift" "func setPetWindowInteractive"
require_text "$RUNNER/MiuRunner+Placement.swift" "func petShouldAcceptMouseEvents(hidden: Bool, frontWindows: [NSRect]) -> Bool"
require_text "$RUNNER/MiuRunner+Placement.swift" "window.ignoresMouseEvents"
require_text "$RUNNER/MiuRunner+Placement.swift" "func clampedPetFrame"
require_text "$RUNNER/MiuRunner+Placement.swift" "func candidateScreenCoordinateRects"
require_text "$RUNNER/MiuRunner+Placement.swift" "NSScreen.screens.map"
reject_text "$RUNNER/MiuRunner+Behavior.swift" "petShouldAcceptMouseEvents(hidden: false, quiet:"
reject_text "$RUNNER/MiuRunner+Placement.swift" "guard !hidden, !quiet"

require_text "$RUNNER/MiuRunner+ReminderBubble.swift" "clampedReminderBubbleOrigin"
require_text "$RUNNER/MiuRunner+ReminderBubble.swift" "visibleFrame"
require_text "$RUNNER/V1.0.2_QA_RECORD.md" "Desktop Interaction Checklist"
require_text "$RUNNER/V1.0.2_QA_RECORD.md" "Multi-display"

echo "猫小伴 V1.0.2 hotfix static checks passed"
