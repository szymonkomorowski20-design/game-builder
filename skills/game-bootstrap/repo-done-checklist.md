# Repo definition of done — prove it on disk

Bootstrap is done when the tools say so, not when the files were intended. Run both and paste the
output; report them as two separate results.

```
node tools/gb/gb.js doctor     # presence: files, stamp, brief ledger, settings, input map, git, Godot version, last verify
node tools/gb/gb.js verify     # boot: import → check all scripts → run main scene headless → tests
```

- `doctor` must end with `DONE — no MISS lines`. It checks: `project.godot` + main scene, stamped
  `AGENTS.md`, `CLAUDE.md → @AGENTS.md`, README/STATUS, `.gitignore`/`.gitattributes`, the full `.ai/`
  tree (brief with a Decisions Ledger and nothing pending, STATE/lessons/backlog, specs +
  implemented/archived, ADR template + ADR-001, asset register, spec-writing skill, the four
  checklists), `tools/gb`, `.claude/` settings (valid JSON) + both hooks, input actions, git with ≥ 1
  commit, the Godot binary and its version match, the last verify result.
- WARN lines are not failures but are said out loud (e.g. "test framework not installed yet").
- `verify` must be `PASS`. `SKIP test` is reported as "no test framework yet", never as passing.
- A green `doctor` with a failing `verify` is an unusable repo — never hand it off as done.
