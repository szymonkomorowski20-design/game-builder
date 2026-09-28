# Proof game: "Ucieczka z Krypty" (ROADMAP 9.1, autonomous mode)

A Hades-like action roguelite built by game-builder from the owner's one-line pitch ("gra typu Hades"). It uses the
**autonomous** process: the bot decided with each decision card's recommended option, a fresh `game-checker`
approved the spec, the machine gates ran at every phase, and the owner plays only the finished game. The build took
one session (2026-09-27), on game-builder 0.21.0 → 0.22.0.

Game repo: `Desktop/gry testowe/ucieczka-z-krypty`. It has no commits by the owner's rule; phases are `git write-tree`
snapshots listed in its STATUS.md.

## What was built
- **Scope:** a single area (the brief's rung 3).
- **Map:** 10 chambers — combat, elite, shop, rest — on 4 hand-made layouts with pillars, then the Warden in a larger
  arena.
- **Hero:**
  - a 3-hit combo;
  - a spear throw (a new `special` action);
  - an invulnerable dash.
- **Enemies:**
  - four types: rusher, swarmer (groups of 3), spear thrower (keeps its distance), brute;
  - an elite affix;
  - at most 2 melee attackers at once (attack tokens).
- **Warden:** 3 phases with slam, lunge, nova and a phase-2 volley. Every move is telegraphed with two cues.
- **Gifts:**
  - 18 gifts from three spirits (flame, frost, stone), including 3 duos;
  - rarity;
  - statuses (burn, chill);
  - card choice with reroll.
- **Antechamber:** a training dummy, a shrine with 5 permanent options (health, might, agility, rerolls, second
  chance) and a chronicle.
- **Menus:**
  - a title with a 3D backdrop;
  - pause;
  - settings: volumes, fullscreen, shake, and mercy mode (−20% damage, +2% per death, max 80%).
- **Look and sound:** Kenney Mini Dungeon animated characters and tiles; Kenney impact and interface sounds; the mrbid
  swosh; 4 Game Music Composer tracks. All free, from the gry-wiedza library (CC0 / Unlicense), and 0 paid
  generations.
- **Build:** Windows, 111.6 MB. `gb export --smoke` is clean.

## Numbers
| | |
|---|---|
| Unit tests (GUT) | 126, including the recipes' own |
| Bot scenarios | 31: the template's A1–A8, K1–K14, and completability on 3 seeds |
| Detection proofs (mutations) | 31, all detected in the end. The first versions of three checks missed their mutation and were strengthened (K1 overlay, K3 spear, K9 pillars) |
| Spec review rounds (checker, spec mode) | 4 (CHANGES-REQUIRED ×3, then NITS) |
| Phase reviews | P1 CHANGES-REQUIRED → APPROVE; P2 NITS; P3 CHANGES-REQUIRED → APPROVE; P4 CHANGES-REQUIRED (spec text) → APPROVE; P5 NITS → fixed; P6 CHANGES-REQUIRED → fixed, then a re-check on a clean snapshot found one more (below) → fixed, `gb verify` green on a fresh checkout |
| Machine playtests | phases 1–6: every Done-when item OBSERVED on a clean snapshot (3 look defects fixed in phases 1–2; one cosmetic overlap left in STATUS.md) |

## What the machine gates caught (and a human would have found later)
| Found by | Problem | Fix |
|---|---|---|
| A8 (bot run) + a hit log | a depth-2 room cost ~50/60 HP through overlapping melee tells | attack tokens (≤ 2 at once), a softer early curve |
| balance contract (recipe 36) | "Iskry" +10.6 DPS vs a median 3.5; "Kamienna Skóra" +42% vs 17% effective HP | numbers cut; the contract stays as a test |
| balance contract (phase 6) | an elite brute would hit for 27% of the hero's health (the brief caps it at 20%) | elite damage capped by `max_hit` |
| A3 | a door into a shop or rest sent the hero straight through the next door (the physics server still had them at the old door) | doors arm after 0.3 s |
| A3, A7 | mashing attack picked a gift unseen and skipped the victory screen | input delays (0.35 s / 1 s) |
| the first gift-choice shot | amplifier gifts (burn/chill bonuses) offered before any burn/chill source | amplifiers need their spirit first |
| K11 (completability) | enemies and the bot pushing into pillars | steering around pillars |
| the playtester | the Warden's telegraph turned it into a flat red shape; the hero at the screen edge; tall readiness bars | telegraph strength, camera follow, thin meters |
| recipe tests 48/52 | sorting StringNames depends on load order | compare Strings (plugin fix) |
| the checker on a clean snapshot | the FPS measurement's output path (`res://.ai/verify/perf/fps.json`) failed `gb lint` on every fresh checkout, so `gb verify` never reached the tests; it passed only in the maker's copy, where an old file lay | lint skips generated `.ai/` paths (plugin 0.24.0); the test creates its folder |

## What the plugin learned (released)
- **0.21.1:**
  - `gb doctor` accepts "no commit yet" in autonomous mode;
  - `game-checker` has a spec review mode.
- **0.22.0:**
  - attack tokens and the careful bot in the `action-roguelite-3d` template;
  - `note()` in scenarios, shown by `gb scenario`;
  - the StringName-sort fix;
  - new pitfalls (StringName sort, lambda capture, print vs note);
  - the snapshot procedure for autonomous mode;
  - the rule that spec review escalates only blocking items from round 3.
- **0.23.0 (this report):**
  - `gb snapshot` / `gb snapshot checkout`, so a reviewer verifies a clean copy while the maker keeps working;
  - `gb tools update` refreshes the harness too;
  - the template's doors arm and its boon choice ignores a mashed pick;
  - the template bot stops walking when the room changes.
- **0.24.0:** `gb lint` no longer treats generated `res://.ai/…` paths as broken references.

## Open
- **`gb perf` process/physics monitors.** In a window, `TIME_PROCESS` / `TIME_PHYSICS_PROCESS` report ~18 / 16 ms even
  in a near-empty scene at a 4.17 ms frame, so the `process_ms` / `physics_ms` budget lines fail everywhere. Frame
  time (the meaningful budget) has ~4× headroom. Needs a look at what those monitors measure on 4.7.
- **Run length.** The bot finishes a run in ~3 min; a person will likely need ~8–12, below the brief's 15–25. The
  number of waves and chambers are Tuning values, left for the owner's verdict.
- **The owner's playtest gate:** keep / tweak / cut per mechanic, using STATUS.md's checklist. Then the commits, on
  the owner's word.
- **Process cost.** Autonomous mode needed four spec review rounds and several phase review rounds; each found real
  gaps. The reviews were run as general-purpose agents given the checker's role file, because the plugin itself is
  not installed in this session.
