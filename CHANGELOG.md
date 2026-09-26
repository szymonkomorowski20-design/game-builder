# Changelog

## 0.6.0 — 2026-09-26 · roles, release and diagnosis (stage 6, part 1)
- **Agents** (few on purpose — Claude Code Game Studios measured that heavier process produced a worse game): `game-checker` (reviews the diff against the spec only, opens with "what the diff does NOT do", read-only), `game-tester` (derives tests from the spec before reading code, detection proof), `game-playtester` (runs the game, `gb shot --movie`, looks at every image, `Run result` per Done-when item, questions for the human — never judges feel), `game-researcher` (recipes → pinned 4.7 docs → knowledge base, verified at source, lists what it could not establish). Wired into game-implement (checker + playtester before the human gate), game-test, game-spec, game-pre-implement.
- **Skills:** `game-release` (credits, smoke-tested exports, web limits, save compatibility, human publishes), `game-diagnose` (reproduce with gb → hypothesis ledger → failing test → minimal fix → incident), `game-playtest` (tasks, observation, keep/tweak/cut → Tuning values or backlog), `game-assets` (library search, allowed licences, Godot 4.7 import, register in the same commit).
- `gb export --smoke`: runs the exported desktop build headless for 180 frames with `--log-file` and fails on errors in its log. Detection proven: a resource dropped by `exclude_filter` passes the editor run and fails the smoke run.
- `gb credits`: `CREDITS.md` from `.ai/assets/REGISTER.md`; fails on non-commercial, no-derivatives, unknown or proprietary licences and on registered files that do not exist.
- Scaffold: pixel-art projects get `window/stretch/scale_mode="integer"`; `credits.js` shipped to game repos; one list of framework files for scaffold and `tools update` (test enforces it). Session router and AGENTS.md task router name the new skills; open incidents route to game-diagnose.

## 0.5.0 — 2026-09-26 · knowledge: recipes, Godot 4.4–4.7 reference, audio (stage 4)
- **Recipes** (`recipes/`, 35): tested mechanics for Godot 4.7 — movement, camera, shake, parallax, health, hitbox/hurtbox, projectile, weapon, inventory, crafting, shop, achievements, versioned save/load (tier A, detection-proven), state machine, pause, scene transitions, settings + rebinding, dialogue, quests, pooling, audio voices, localization, HUD, enemy AI, behavior tree, navigation, tilemap, procedural dungeon, day/night, grid puzzle, cards, hit-stop, hit-flash shader, adaptive music (`AudioStreamInteractive`), SFX variants (`AudioStreamRandomizer` + `AudioStreamPolyphonic`). 98 GUT tests + 11 bot scenarios (`node tools/recipes.js`). Each has README (Problem/Solution/Tuning/Pitfalls/Test) and an index in `recipes/README.md`.
- `gb recipe list` / `gb recipe add <NN…>` (plugin copy): copies recipes into a game with their tests, resolves dependencies from `class_name` use, rewrites `res://` paths, never overwrites. Proven end to end: recipes added to a fresh scaffold pass `gb verify` there.
- `gb shot --movie`: screenshot through Godot's Movie Maker (`--write-movie`) — no harness or game code needed, also records the audio and reports its peak (`audio peak -inf dBFS` = silence), the first automated proof that a game makes sound. Default when the harness is missing.
- `skills/game-implement/godot-4.4-4.7-changes.md`: GDScript-breaking and behaviour changes extracted from the official migration guides of the pinned 4.7 docs (e.g. `Resource.duplicate(true)` in 4.5, Jolt default in 4.6, explicit `return` in typed overrides and keyboard device IDs in 4.7, web audio Sample mode).
- `skills/game-implement/godot-pitfalls.md`: ~35 pitfalls measured while building the harness, Pong and the recipes (symptom → cause → fix).
- `game-implement`: mandatory `Run result: OBSERVED | NOT VERIFIED | N/A` line with evidence in `.ai/evidence/` for every player-visible step (adapted from Claude Code Game Studios, MIT); reads the change list and pitfalls; starts from recipes.
- New skill `game-audio`: legal sources (library search by sound description, licence traps found in gry-wiedza wave 05), import, buses, recipes, web audio limits, proof via `gb shot --movie`, human judges the sound.
- Knowledge base skill updated for gry-wiedza wave 05 (pinned 4.7 docs, audio guides, MIDI assets, audio licence traps). AGENTS.md task router: audio, recipes, Godot changes. Scaffold adds `.ai/evidence/`.
- Found by the recipe tests: `JSON.parse_string` on bad input is an engine error (use `JSON.new().parse`); `get_shader_parameter` is `null` until set; translations must be registered or the UI shows keys; `get_stream_playback()` on a stopped player errors; float accumulation in timers; `is_navigation_finished` uses `target_desired_distance`.

## 0.4.0 — 2026-09-25 · platformer-2d starter template (stage 5, first template)
- `gb scaffold --template platformer-2d`: tested side-view platformer starter — acceleration/friction run, jump defined by height + time to apex (`JumpMath`), faster fall, variable jump, coyote time, jump buffer, all numbers in `PlayerTuning` (`data/player_tuning.tres`); level with gap, platforms, 5 coins, goal, respawn; HUD; implemented spec with Tuning table; 3 unit tests + 8 behaviour scenarios (P1–P8).
- Found by the template's own scenarios: whole-step gravity overshot the designed jump (75.25 px vs 72) → trapezoid integration after the jump impulse (72.07 px); the player walked off the level after the goal (seen in the p8 screenshot) → right wall + freeze at goal, expectation added.
- game-bootstrap: template decision card (Q1b), `--template` flag; scaffold prints concrete import errors.

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
