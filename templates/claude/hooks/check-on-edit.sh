#!/usr/bin/env sh
# PostToolUse (game repo): after an edit to a .gd/.tscn/.tres file, load every script in one engine
# boot (gb check, ~0.3 s) and run the static lint. On failure, exit 2: the errors go back to the
# agent immediately, so a parse error is fixed in the same turn instead of surfacing at verify time.
payload="$(cat)"
fp="$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
case "$fp" in
  *.gd|*.tscn|*.tres) ;;
  *) exit 0;;
esac
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
out="$(node "$ROOT/tools/gb/gb.js" check --path "$ROOT" 2>&1)" || { printf '%s\n' "$out" >&2; exit 2; }
lint="$(node "$ROOT/tools/gb/gb.js" lint --path "$ROOT" 2>&1)" || { printf '%s\n' "$lint" >&2; exit 2; }
exit 0
