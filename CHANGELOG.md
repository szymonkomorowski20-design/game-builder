# Changelog

## 0.3.0 — 2026-09-25 · spec → implement → test (stage 3)
- Skills: `game-spec` (Open Questions gate, Tuning table, runnable Done-when, playtest gates; template), `game-pre-implement` (game compatibility surfaces: @export renames, saves, input actions, res:// paths, replays/baselines; physics/determinism/perf risks), `game-implement` (RED first, gb verify every step, look at shots, playtest gate, tuning loop, never re-record to green, keep tools current), `game-test` (spec-first derivation, frozen plan, four instruments, detection proof tiers, anti-flake; techniques + plan template).
- Router and game-start route through the new skills; AGENTS.md template task router; scaffold adds `.ai/test-plans/` and `.ai/runs/`.
- `gb scenario --window --accept|--compare` for scenario screenshots; `gb tools update`; `gb doctor` warns when a game's tools/gb is older than the plugin.
- Dogfood 1: Pong built with the plugin in three phases (docs/dogfood/pong.md); its lessons are now in game-test/game-implement.
- 3 new evals (written, not yet run).

## 0.2.0 — 2026-09-25 · verification layer (stage 2)
- `gb_harness` addon (autoload `GbHarness`, inert in normal play): seeded RNG, bot-player scenarios (`GbScenario`: press/tap/hold/wait/node/expect_*), record → replay with final-state match for nodes in group `gb_track`, screenshots, performance sampling. Measured on 4.7.2: physics deterministic, input injection works headless, capture needs a window.
- `gb`: `scenario`, `record`, `replay`, `shot` (baseline compare/accept via `imgdiff.gd`), `perf` (vs `.ai/perf-budget.json`), `lint` (broken res:// refs, Godot 3 APIs, licence register, harness), `export` (presets, missing-template diagnosis), `harness install`, `tests install gut`; `verify` = import → check → lint → run → test → scenarios → replays (`--quick` stops after test).
- GUT 9.7.1 vendored (MIT); `gb test` parses GUT totals and writes JUnit.
- Scaffold adds harness, GUT, smoke scenario, example unit test, export presets (Windows Desktop + Web), perf budget, CI workflow (Godot Linux build → `gb verify`), check-on-edit PostToolUse hook; `--adopt` installs harness/GUT through the engine.
- `gb doctor` checks the new pieces and warns about missing export templates.
- Fixes found by the new tests: `check_all.gd` no longer re-loads itself (hang/crash without `.gdignore`); scenarios reach the harness by path (autoload names are not identifiers under `--script`); harness lint is an error only in stamped repos (honest adoption baselines).
- `docs/mcp-evaluation.md`: Godot MCP servers reviewed; `gb` stays the verification instrument.

## 0.1.0 — 2026-09-25 · foundation (stage 1)
- Plugin skeleton: manifest, marketplace, enable scripts, SessionStart hooks (workflow router for game repos, framework-version check), Sailes disabled per game repo to avoid double routing.
- `gb` verification CLI for Godot 4: `godot`, `import`, `check` (all scripts in one boot), `run` (headless, log-based — runtime errors fail even with exit code 0), `test` (GUT/gdUnit4 if installed), `verify`, `doctor`, `kb`/`assets` (gry-wiedza knowledge base), `scaffold` (plugin-only, never overwrites; `--adopt` for existing projects).
- Skills: `game-start`, `game-discovery` (checklists, decision cards, scope ladder, brief templates), `game-bootstrap` (decision engine, engine baseline, adopt procedure, knowledge base, done checklist).
- Game repo templates: stamped AGENTS.md, `.ai/` tree with local spec-writing skill and checklists, `.claude/` guardrails (session memory, protected paths).
- Tests: gb unit + integration against real Godot fixtures, hooks, guard, scaffold incl. an end-to-end bootstrap, release hygiene (versions, changelog, YAML-safe skill frontmatter); `claude plugin validate` passes.
