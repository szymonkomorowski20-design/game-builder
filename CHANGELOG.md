# Changelog

## 0.1.0 — 2026-09-25 · foundation (stage 1)
- Plugin skeleton: manifest, marketplace, enable scripts, SessionStart hooks (workflow router for game repos, framework-version check), Sailes disabled per game repo to avoid double routing.
- `gb` verification CLI for Godot 4: `godot`, `import`, `check` (all scripts in one boot), `run` (headless, log-based — runtime errors fail even with exit code 0), `test` (GUT/gdUnit4 if installed), `verify`, `doctor`, `kb`/`assets` (gry-wiedza knowledge base), `scaffold` (plugin-only, never overwrites; `--adopt` for existing projects).
- Skills: `game-start`, `game-discovery` (checklists, decision cards, scope ladder, brief templates), `game-bootstrap` (decision engine, engine baseline, adopt procedure, knowledge base, done checklist).
- Game repo templates: stamped AGENTS.md, `.ai/` tree with local spec-writing skill and checklists, `.claude/` guardrails (session memory, protected paths).
- Tests: gb unit + integration against real Godot fixtures, hooks, guard, scaffold incl. an end-to-end bootstrap, release hygiene (versions, changelog, YAML-safe skill frontmatter); `claude plugin validate` passes.
