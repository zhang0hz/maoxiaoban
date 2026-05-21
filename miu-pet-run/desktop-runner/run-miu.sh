#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT/miu-pet-run/desktop-runner/MiuDesktopRunner"
ASSETS="$ROOT/miu-pet-run/phase1-actions/frames"

exec "$RUNNER" --asset-root "$ASSETS"
