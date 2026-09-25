# Decision engine — classify the game, produce the setup manifest

Carry the confirmed brief in; ask only what it does not answer. Rounds of 3–4 via `AskUserQuestion`.
Every **decision** below is a card (`game-discovery/decision-card.md`); facts are plain questions.

## Q1 — Engine (decision)
| Option | ✅ | ⚠️ |
|---|---|---|
| **Godot 4.x** (recommended default) | `gb` verifies every change (import, scripts, headless run, tests); the local knowledge base has the full Godot docs + demo projects; small, free, fast iteration | smaller asset store than Unity; console ports need third parties |
| Unity 6 | huge asset store and tutorials; mature mobile/console pipeline | this workflow cannot verify it yet — every "done" rests on the human's own test; licence terms; heavier editor |
| Other (Unreal, Bevy, raylib, web) | fits specific needs | no verification layer here |
Pin the exact Godot version from the installed binary (`gb godot`); the project's `config/features` records it.

## Q2 — Dimension & camera (usually already in the brief → confirm)
2D side / 2D top-down / 2D isometric / 3D third-person / 3D first-person / 3D top-down.

## Q3 — Target platforms (fact) → renderer (decision)
| Renderer | Choose when | Cost |
|---|---|---|
| Compatibility (`gl_compatibility`) | web is a target; 2D; low-end hardware | fewer advanced 3D effects; the only renderer Godot 4 web export supports |
| Forward+ (`forward_plus`) | desktop 3D with modern lighting/effects | no web export; heavier GPU requirements |
| Mobile (`mobile`) | Android/iOS 3D, or light 3D on desktop | some Forward+ effects missing |
Default recommendation: 2D → Compatibility; 3D desktop-only → Forward+; anything with web → Compatibility.

## Q4 — Resolution & pixel art (decision for 2D)
- Pixel art: low base resolution (320×180, 384×216, 480×270 — all scale cleanly to 1080p), viewport stretch, nearest filtering, pixel snap. `--pixel-art` sets these; the window opens at ×4.
- Smooth 2D/3D: 1280×720 base, `canvas_items` stretch, aspect `expand`.
- Ask about the reference games' look, not about numbers.

## Q5 — Input devices (fact)
Keyboard+mouse / gamepad / touch. Scaffold creates keyboard + gamepad actions (`move_*`, `jump`, `action`, `pause`); touch needs UI work later (note it in the backlog/spec).

## Q6 — Test framework (decision)
| Option | ✅ | ⚠️ |
|---|---|---|
| **GUT** (recommended) | pure GDScript, mature, simple CLI (`gut_cmdln.gd`); vendored with game-builder (9.7.1, tested on Godot 4.7.2) — installs offline, `gb test` parses its totals | assertion style older |
| gdUnit4 | richer assertions, scene runner, mocks; GDScript and C# | not vendored — install from the Asset Library yourself; `gb test` detects and runs it |
| none for now | nothing to install | logic regressions only caught by playing; `gb test` stays SKIP |

## Q7 — Git LFS (decision)
| Option | ✅ | ⚠️ |
|---|---|---|
| No LFS (recommended for small prototypes) | simplest; works everywhere | repository grows with every asset revision |
| LFS | repo stays small with big textures/audio/models | every clone needs `git lfs install`; GitHub LFS quota; set up BEFORE the first binary commit |
Recommend LFS when the brief expects >~300 MB of assets or large 3D/audio sources.

## Q8 — Optional modules (activate only when the brief needs them)
Record them in the manifest; they get their own specs later — never scaffolded "just in case":
save/load · settings menu & key rebinding · localization · dialogue system · inventory · procedural generation · local multiplayer · online multiplayer · achievements/Steamworks · analytics/telemetry (privacy!) · modding.

## Output — setup manifest (goes into the brief's Decisions Ledger + ADR-001)
```
Engine: Godot 4.x (pinned: 4.x.y) · Dimension: 2D/3D · Renderer: … · Base resolution: …×… (pixel art: yes/no)
Platforms: … · Input: … · Tests: gut/gdunit4/none · LFS: yes/no
Modules (later specs): …
```
Then `gb scaffold` with the matching flags.
