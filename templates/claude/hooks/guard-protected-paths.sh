#!/usr/bin/env sh
# PreToolUse guard (game repo). Reads the tool-call JSON on stdin; blocks (exit 2 + reason on stderr)
# when a call touches the protected surface. No jq — the two fields that matter are extracted with sed.
#
# Only the FIELD is inspected, never the whole payload: a Write whose CONTENT merely mentions
# ".godot/" or "push --force" (AGENTS.md does both) must pass. Matching the raw payload blocks
# documentation edits — a guard that cries wolf gets disabled.
payload="$(cat)"

block() { echo "BLOCKED by guard-protected-paths: $1" >&2; exit 2; }

field() {
  printf '%s' "$payload" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\(\([^\"\\\\]\|\\\\.\)*\)\".*/\1/p" | head -1
}

cmd="$(field command)"
# JSON-escaped Windows separators (\\) → /
fp="$(field file_path | sed 's#\\\\#/#g')"

# --- Commands (Bash tool) ---
case "$cmd" in
  *'push --force'*|*'push -f'*)   block "force-push is denied (hard safety rules)";;
  *'reset --hard'*)               block "reset --hard is denied — use git restore / git revert";;
  *'butler push'*|*'steamcmd'*)   block "publishing a build needs the human's explicit approval of that release";;
esac

# --- Paths (Edit/Write tools) ---
case "$fp" in
  */.godot/*|.godot/*)
    block ".godot/ is Godot's cache — change the source asset or project setting instead";;
  *.import)
    block "*.import files are written by Godot's import dock — change import settings in the editor (or ask the human)";;
  */.ai/specs/implemented/*|.ai/specs/implemented/*)
    block "implemented specs are history — write a new spec instead";;
esac

exit 0
