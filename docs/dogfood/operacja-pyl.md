# Proof game: "Operacja Pył" (ROADMAP 9.2, autonomous mode)

A three-mission military FPS campaign on the Moon, in the Call of Duty mould, built by game-builder from the owner's
pitch. It uses the **autonomous** process: the bot decided with each decision card's recommended option, a fresh
`game-checker` approved the spec, the machine gates ran at every phase, and the owner plays only the finished game. It
was built on 2026-09-28 on game-builder 0.25.0 → 0.26.1, from the `military-fps-3d` template.

Game repo: `Desktop/gry testowe/operacja-pyl`. It has no commits by the owner's rule; phases are `git write-tree`
snapshots listed in its STATUS.md.

## What was built
- **Missions** (a step runner: reach, fight, hold, charges, defend, escape; each mission is a list of steps in its
  scene):
  1. **Lądowisko:** the template's courtyard and warehouse reskinned as a moon outpost; a relay to hold,
     reinforcements, the lander.
  2. **Kopalnia:** a canyon, a mine yard, a tunnel, charges on two drills, a 60 s defence from two sides, the lander.
  3. **Reaktor:** a base yard, a reactor hall with an armoured heavy, a 4 s console hold, then a 90 s escape under a
     red alarm, with runners from ahead.
- **Enemies:** rifleman, assault (a shotgun with one roll per pellet, charges), grenadier (a ballistic throw, a red
  ring and beeps, one grenade per squad), heavy (a front plate: head and back only; an LMG). At most 2 fire at once.
- **Player:** a rifle and a pistol from recipes 53–56, grenades, regenerating health, ammo packs from fallen soldiers
  and top-ups at checkpoints (added when the bot ran dry in the defence).
- **Menus:** a title over a moon backdrop, mission select, briefings, results with records, pause with a checkpoint
  restart, settings (look speed, FOV 80–110, inverted look, pad aim assist, volumes, fullscreen, three difficulty
  levels), a versioned save that never overwrites an unreadable file, credits.
- **Look and sound:** KayKit Space Base models, ambientCG surfaces, Kenney sounds, mrbid's alarm and heartbeat, 6
  Game Music Composer tracks. All free, from the gry-wiedza library; 0 paid generations.
- **Build:** Windows, `OperacjaPyl.exe` + `OperacjaPyl.pck` (122.7 MB); `gb export --smoke` is clean.

## Numbers
| | |
|---|---|
| Unit tests (GUT) | 90, including the recipes' own |
| Bot scenarios | 34: the template's M1–M10, the phases' P1–P5, the whole campaign through the menus, mission 1 on 3 seeds, every mission on Rekrut and Weteran |
| Detection proofs (mutations) | 54 recorded in the spec's Evidence (phases 2–5), all detected in the end; two more exposed a gap, now closed (below). Phase 1 (the look and sound) recorded none |
| Phase reviews | P1 CHANGES-REQUIRED → NITS; P2 CHANGES-REQUIRED → APPROVE; P3a NITS; P3b NITS; P3c NITS; P4 NITS; P5 final: see STATUS.md |
| The bot, normal difficulty | mission 1: 79 s, 0 deaths; mission 2: ~150 s, 0–1; mission 3: 106 s, 0; the whole campaign through the menus: 0 deaths, no unfair spawn |
| Performance (the reactor hall fight, vsync off) | frame average 1.97 ms, p95 2.08 ms; physics p95 1.7 ms |

## What the machine gates caught (and a human would have found later)
| Found by | Problem | Fix |
|---|---|---|
| the checker's clean-copy verify (phase 1) | two mrbid WAVs whose headers declare more bytes than the file: Godot refuses them on the *first* import, so every fresh clone failed while the maker's warm cache passed | headers fixed; `gb lint wav-header` (plugin 0.26.0) |
| the checker (phase 2) | the grenadier's throw ignored the spec's speed | a ballistic solve at 14 m/s |
| the bot (phase 3b) | the rifle ran dry in the 60 s defence: 180 rounds, no resupply | ammo packs from fallen soldiers, checkpoint top-ups (a recorded design addition) |
| the bot (phase 3c) | the escape's runners never came: their spawn points were past the 45 m fair-spawn limit from the console | spawn points behind the hall's front wall |
| the shots (phases 3b, 3c) | the player ended inside the lander model; the alarm shot showed no red | a solid ship with its boarding area in front; the shot faces the way out |
| the checker (phase 3c) | the alarm lights stayed on after the mission ended | switched off at the end, tested |
| the checker (phase 4) | the pause menu opened over the death screen; unit tests ran on the player's real save path | `is_dying()`; `Game.is_test_run()` recognises GUT |
| the campaign run (phase 5) | the bot kept walking after a mission ended and touched the freed scene | the routes stop at completion |
| `gb perf` (phase 5) | a ~8 ms physics step every second: a new mesh and material per tracer | shared ones (also in the template, 0.26.1) |
| the export smoke (phase 5) | Windows 11 Smart App Control blocked the new unsigned exe with the pack inside | `embed_pck=false` (the default for new games, 0.26.1) |
| a detection proof (phase 5) | "at most 2 fire at once" was held by no test: the careful bot still wins against 5 | a unit contract (also in the template, 0.26.1) |

## What the plugin learned (released)
- **0.25.1 → folded into 0.26.0:** `gb lint wav-header`; the pitfall "a failing first import is reproduced on a clean
  copy before it is dismissed".
- **0.26.0:** a scenario may declare `const GB_MINUTES := N` (1–30) for a long run, such as a whole campaign played by
  a bot (the old fixed cap was 5 simulated minutes).
- **0.26.1:**
  - the template's tracers share their mesh and material;
  - the template pins the fire limit in a contract;
  - `gb perf` warms up for 1 s as well as 30 frames, and its help says the process / physics monitors are the worst
    frame of each second;
  - new games export Windows with the pack beside the exe, and `gb export --smoke` names the Smart App Control cause;
  - pitfalls for both.

## What the owner decides (STATUS.md, "Twoja kolej")
Play the campaign and judge what no bot can: whether the guns feel good, whether the two-sided defence is too much,
whether the escape is tense, which difficulty level is right. Then "commituj" for the game repo's first commit.

## Honest limits
- The bot aims better than most people; its runs are fairness floors, not the difficulty a person feels.
- Soldiers and weapons are built from primitives (the library has no rigged soldier or firearm model).
- Three missions of 6–10 minutes each (for a person) is the brief's rung 3, not a full campaign.
