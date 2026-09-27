#!/usr/bin/env sh
# PreToolUse guard for a game repo. Claude Code sends the tool call as JSON on stdin; exiting with 2 and a
# message on stderr stops the call and shows the message to the agent.
#
# We look only at the `command` (Bash) and `file_path` (Edit/Write) fields — never at the whole payload —
# so writing a document that merely MENTIONS ".godot/" or a force-push (AGENTS.md does) is allowed.
# A guard that blocks harmless edits gets switched off, and then it protects nothing.
input="$(cat)"

deny() {
  printf 'guard-protected-paths stopped this call: %s\n' "$1" >&2
  exit 2
}

# tool_input.<name> as plain text, parsed as real JSON (Node is already required by gb; jq may be missing).
tool_input() {
  printf '%s' "$input" | node -e '
    let raw = "";
    process.stdin.on("data", (d) => (raw += d)).on("end", () => {
      try {
        const value = (JSON.parse(raw).tool_input || {})[process.argv[1]];
        if (typeof value === "string") process.stdout.write(value);
      } catch {}
    });' "$1"
}

command_line="$(tool_input command)"
# Windows paths → forward slashes, so one pattern matches both.
target="$(tool_input file_path | tr '\\' '/')"

# Shell commands with consequences only the human may choose.
case "$command_line" in
  *'push --force'* | *'push -f'*) deny "force-pushing rewrites shared history (hard safety rules)" ;;
  *'reset --hard'*) deny "reset --hard throws work away — use git restore or git revert" ;;
  *'butler push'* | *'steamcmd'*) deny "publishing a build needs the human's explicit go for that release" ;;
esac

# Files that are generated or closed.
case "$target" in
  */.godot/* | .godot/*) deny ".godot/ is Godot's cache — change the source asset or the project setting instead" ;;
  *.import) deny "*.import files are written by Godot's import dock — change import settings in the editor (or ask the human)" ;;
  */.ai/specs/implemented/* | .ai/specs/implemented/*) deny "implemented specs are history — write a new spec instead" ;;
esac

exit 0
