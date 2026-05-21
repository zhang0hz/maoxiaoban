#!/usr/bin/env bash
set -euo pipefail

pkill -f "Miu.app/Contents/MacOS/MiuDesktopRunner" || true
pkill -f "猫小伴.app/Contents/MacOS/MiuDesktopRunner" || true
pkill -f "desktop-runner/MiuDesktopRunner" || true
