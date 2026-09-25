#!/usr/bin/env sh
# SessionStart (game repo): print session memory so "read STATE.md at session start" is enforced,
# not remembered. Warns when the snapshot is older than the work in the history.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE="$ROOT/.ai/STATE.md"

cat "$STATE" 2>/dev/null

# Staleness: commits since the recorded Last-commit that are NOT the snapshot's own write.
if [ -f "$STATE" ]; then
  claimed="$(sed -n 's/^[Ll]ast-commit:[[:space:]]*\([0-9a-fA-F]\{4,\}\).*/\1/p' "$STATE" | head -1)"
  if [ -n "$claimed" ] && git -C "$ROOT" rev-parse --verify --quiet "$claimed^{commit}" >/dev/null 2>&1; then
    total="$(git -C "$ROOT" rev-list --count "$claimed..HEAD" 2>/dev/null || echo 0)"
    snaps="$(git -C "$ROOT" rev-list --count "$claimed..HEAD" -- .ai/STATE.md 2>/dev/null || echo 0)"
    work=$((total - snaps))
    if [ "$work" -gt 0 ]; then
      echo "--- WARNING: .ai/STATE.md was written at $claimed; $work commit(s) of work came after it."
      echo "    Verify before trusting it, and update it together with the history."
    fi
  fi
fi

echo "--- Task Router: see AGENTS.md · verify with: node tools/gb/gb.js verify ---"
