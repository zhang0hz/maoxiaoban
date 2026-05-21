#!/usr/bin/env bash
set -euo pipefail

SOURCE="/Users/zhanghz/Documents/Codex/2026-05-12/new-chat"
TARGET="/Users/zhanghz/Documents/猫小伴-电子宠物"

mkdir -p "$TARGET"

rsync -a \
  --exclude .git \
  --exclude .DS_Store \
  --exclude miu-pet-run/desktop-runner/module-cache \
  --exclude miu-pet-run/desktop-runner/miu-runner.log \
  --exclude miu-pet-run/desktop-runner/miu-runner.pid \
  "$SOURCE/" "$TARGET/"

printf "迁移完成: %s\n" "$TARGET"
printf "文件数: "
find "$TARGET" -type f | wc -l
printf "大小: "
du -sh "$TARGET" | awk '{print $1}'
