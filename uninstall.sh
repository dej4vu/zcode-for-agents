#!/bin/bash
# zcode-for-agents 卸载脚本：移除 zcode wrapper 与指针段。
# skill 本体通过 skills CLI 卸载：npx skills remove use-zcode -g
set -euo pipefail

MARKER_START="<!-- zcode-for-agents:start -->"
MARKER_END="<!-- zcode-for-agents:end -->"
WRAPPER="${HOME}/.local/bin/zcode"

echo "==> 移除 wrapper: $WRAPPER"
if [[ -f "$WRAPPER" ]] && grep -q "zcode-for-agents install.sh" "$WRAPPER" 2>/dev/null; then
  rm "$WRAPPER"
  echo "    已删除"
elif [[ -e "$WRAPPER" ]]; then
  echo "    跳过（不是本项目创建的 wrapper）"
else
  echo "    不存在，跳过"
fi

strip_pointers() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if grep -qF "$MARKER_START" "$file"; then
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
      $0 ~ s {skip=1; next}
      $0 ~ e {skip=0; next}
      !skip {print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "    已移除指针段: $file"
  fi
}

echo "==> 移除指针段"
strip_pointers "${HOME}/.codex/AGENTS.md"
strip_pointers "${HOME}/.claude/CLAUDE.md"

echo "完成。若通过 skills CLI 安装过 skill，请再执行：npx skills remove use-zcode -g"
