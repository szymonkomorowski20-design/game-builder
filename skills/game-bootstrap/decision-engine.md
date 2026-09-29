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

## Q1b — Start from a template? (decision)
Templates are tested starting points: code, scenes, tuning resource, behaviour scenarios and an
implemented spec describing them (`gb scaffold --template <name>`; list: `templates/games/`).
| Option | ✅ | ⚠️ |
|---|---|---|
| **Template** matching the brief (e.g. `platformer-2d`) | tuned movement + tests on day one; the first spec changes a working game | the template's structure becomes yours — read its spec first; placeholder art |
| Empty project | nothing to unlearn; unusual genres | movement/feel built and tested from scratch |
Recommend a template only when its genre matches the brief's core loop.

Available templates (each: implemented spec, Tuning resource, unit tests + behaviour scenarios green at scaffold time):
| Template | Core loop | Tests |
|---|---|---|
| `platformer-2d` | run & jump (coyote time, buffer, variable jump), coins → goal | 8 scenarios P1–P8 + unit |
| `topdown-2d` | 8-direction movement, shooting, chasing enemies with contact damage, waves, heart, win/lose | 8 scenarios T1–T8 + unit |
| `grid-puzzle-2d` | push-box puzzle: single-step moves, undo, restart, 3 levels, BFS solver proving each level solvable | 4 scenarios G1–G4 + unit |
| `cards-2d` | card combat: seeded deck, hand, energy, attack/block cards as data, enemy intents, win/lose | 4 scenarios C1–C4 + unit (incl. a balance contract) |
| `platformer-3d` | 3D run & jump on the ground plane (coyote time, buffer, variable jump), chase camera on a spring arm that stays in front of walls, coins → goal; Forward+, Jolt | 7 scenarios D1–D7 + unit |
| `fps-3d` | first-person shooter: mouse/stick look (screen_relative), movement relative to the view, hitscan weapon with fire interval, targets with health (one moving, one behind cover), clear the arena; adds its own `shoot` (LMB/F/RT) and `look_*` actions | 6 scenarios F1–F6 + unit |
| `action-roguelite-3d` | Hades-like action roguelite (original): hub with training dummy and upgrade shrine; runs of 5 rooms with director waves, boon choices, doors that show their reward; two enemy types with readable telegraphs; a phased boss; melee combo + invulnerable dash; death banks embers, upgrades saved. Built on recipes 05, 13, 43, 47–52 (added with their tests); pair it with `gb doc genre-action-roguelite`; adds `attack` and `dash` actions | 8 scenarios A1–A8 (A8: a bot wins the whole base run) + unit contracts (readability, balance) |
| `military-fps-3d` | Call of Duty-like campaign mission (original): start yard → courtyard → warehouse → radio (hold E) → reinforcements → extraction; rifle + pistol with rpm, magazines, tactical/empty reloads, spread/bloom, ADS, a learnable recoil pattern, falloff, head/body zones; sprint, crouch under low cover, regenerating health with direction arcs, pad aim assist; soldiers that start dug in, peek in bursts, miss their first shots, get suppressed, flank campers and bark (at most 2 fire at once); fair spawns; checkpoints. Built on recipes 41, 49, 53–57; pair it with `gb doc genre-military-fps`; adds `shoot`, `aim`, `reload`, `sprint`, `crouch`, `switch_weapon`, `look_*` | 10 scenarios M1–M10 (M8: a bot completes the mission; M10: running past an arena starts nothing ahead) + unit contracts (TTK, lethality, readability, fair spawns) |
| `rts-3d` | Warcraft / StarCraft-like skirmish (original) against a computer opponent on a mirrored 72 m map: workers gather gold and wood, build farms, barracks and a stable on a grid that says why it refuses, train footmen, archers and riders in a counter triangle; selection by click, box, double-click and control groups, the smart right-click, shift queues, attack-move, formation targets; the RTS camera with a minimap; fog of war; a computer player at three honest difficulties. Built on recipes 58–65; pair it with `gb doc genre-rts`; adds `attack_move`, `stop`, `build_menu`, `cmd_1`–`cmd_4`, `cam_*`, and its own perf budget (an 80-unit battle) | 9 scenarios R1–R9 (R9: a bot beats the computer) + unit contracts (complete data, tech tree, the counter triangle at equal cost, economy, sieges) |
| `stealth-parkour-3d` | Assassin's Creed-like stealth and parkour (original) in one greybox city district: climb lipped facades, leap alleys between roofs, hang from edges and climb down (the drop intent), a viewpoint tower that reveals the district and a leap into hay; guards that see (zones, a meter), hear (along paths), check noises, hunt, call for support, search and give up, and find bodies; a crowd to blend into, hay and a bench to hide in; counter-based melee (a tap counters, a hold blocks, drop dodges); notoriety with witnesses and posters, a chase to escape; one assassination contract where detection alerts the target instead of failing. Built on recipes 40, 66–73; pair it with `gb doc genre-stealth-parkour`; adds `sprint`, `sneak`, `drop`, `strike`, `counter`, `camera_*`, and its own perf budget (every guard hunting) | 11 scenarios S1–S11 (S9: a bot completes the contract unseen) + unit contracts (holds in reach, leapable roofs, walkable points, a short routine, the viewpoint, the leap's hay, falls, hits to kill) |

## Q2 — Dimension & camera (usually already in the brief → confirm)
2D side / 2D top-down / 2D isometric / 3D third-person / 3D first-person / 3D top-down.

## Q3 — Target platforms (fact) → renderer (decision)
| Renderer | Choose when | Cost |
|---|---|---|
| Compatibility (`gl_compatibility`) | web is a target; 2D; low-end hardware | fewer advanced 3D effects; the only renderer Godot 4 web export supports |
| Forward+ (`forward_plus`) | desktop 3D with modern lighting/effects | no web export; heavier GPU requirements |
| Mobile (`mobile`) | Android/iOS 3D, or light 3D on desktop | some Forward+ effects missing |
Default recommendation: 2D → Compatibility; 3D desktop-only → Forward+; anything with web → Compatibility.
Show the platform's consequences from `gb doc platforms` (gry-wiedza) on the card: for web, no ENet (WebSocket/WebRTC only), audio without bus effects in Sample mode, saves in IndexedDB, mouse capture only after a click. For Android, the human installs the JDK and SDK; the Play Store needs an AAB (Gradle) and a release keystore.

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

## Q7b — Process weight (decision)
| Option | ✅ | ⚠️ |
|---|---|---|
| **Standard** (default) | a checker and a playtester agent at every phase gate; readiness report per spec; the full paper trail | slower and costlier per phase |
| Light | a short spec, one checker per spec, your own Run result instead of the playtester agent, a human gate at least at the end of each spec | problems found later, so a late fix costs more; not for saves, multiplayer or release |
| Autonomous | you play only the finished game; the bot decides with the recommended options (recorded for your review), the checker approves the spec, and machine gates run between phases, including "a bot can finish it" | decisions you might have made differently, and feel judged only at the end. Only when the human asks for it |
Recommend light for a jam, a toy, a learning project or a one-mechanic experiment (the brief's "why" and deadline answer this). Recommend standard for anything meant for players. The spine never changes. Details: `<plugin>/docs/rigor.md`.

## Q8 — Optional modules (activate only when the brief needs them)
Record them in the manifest; they get their own specs later — never scaffolded "just in case":
save/load · settings menu & key rebinding · localization · dialogue system · inventory · procedural generation · local multiplayer · online multiplayer · achievements/Steamworks · analytics/telemetry (privacy!) · modding.

## Output — setup manifest (goes into the brief's Decisions Ledger + ADR-001)
```
Engine: Godot 4.x (pinned: 4.x.y) · Dimension: 2D/3D · Renderer: … · Base resolution: …×… (pixel art: yes/no)
Platforms: … · Input: … · Tests: gut/gdunit4/none · LFS: yes/no · Process: standard/light
Modules (later specs): …
```
Then `gb scaffold` with the matching flags.
