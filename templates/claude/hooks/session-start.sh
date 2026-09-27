#!/usr/bin/env sh
# SessionStart (game repo): show the session memory, so reading .ai/STATE.md at the start of a session
# happens every time instead of when someone remembers. Warns when the memory is older than the work.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMORY="$ROOT/.ai/STATE.md"

if [ -f "$MEMORY" ]; then
  cat "$MEMORY"

  # STATE.md records the commit it describes ("Last-commit: <hash>"). Every later commit that did not
  # itself update STATE.md is work the memory doesn't know about yet.
  noted="$(grep -i -m 1 '^last-commit:' "$MEMORY" | tr -d '\r' | awk '{print $2}')"
  if [ -n "$noted" ] && git -C "$ROOT" cat-file -e "$noted^{commit}" 2>/dev/null; then
    since="$(git -C "$ROOT" log --format=%H "$noted..HEAD" 2>/dev/null | wc -l)"
    updates="$(git -C "$ROOT" log --format=%H "$noted..HEAD" -- .ai/STATE.md 2>/dev/null | wc -l)"
    unseen=$((since - updates))
    if [ "$unseen" -gt 0 ]; then
      echo "--- WARNING: .ai/STATE.md describes $noted, and $unseen commit(s) of work came after it."
      echo "    Check it against the history before relying on it, and update it along with your work."
    fi
  fi
fi

echo "--- Task Router: see AGENTS.md · verify with: node tools/gb/gb.js verify ---"
