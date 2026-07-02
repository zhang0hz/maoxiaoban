#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT/miu-pet-run/desktop-runner"

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

require_file "$RUNNER/V1.0.1_INTERNAL_STABILITY.md"

require_text "$RUNNER/Info.plist" "1.0.2"
require_text "$RUNNER/Info.plist" "104"

require_text "$RUNNER/PetView.swift" "override func hitTest"
require_text "$RUNNER/PetView.swift" "alphaHitTestThreshold"
require_text "$RUNNER/PetView.swift" "isOpaquePixel"

require_text "$RUNNER/MiuRunner+Menu.swift" "func truncatedMenuTitle"
require_text "$RUNNER/MiuRunner+Menu.swift" "func disabledInfoItem"
require_text "$RUNNER/MiuRunner+Menu.swift" "toolTip"

require_text "$RUNNER/MiuRunner+Placement.swift" "func frontWindowRects"
require_text "$RUNNER/MiuRunner+Placement.swift" "func windowAvoidanceRects"
require_text "$RUNNER/MiuRunner+Placement.swift" "avoiding frontWindows"

echo "猫小伴 V1.0.1 static checks passed"
