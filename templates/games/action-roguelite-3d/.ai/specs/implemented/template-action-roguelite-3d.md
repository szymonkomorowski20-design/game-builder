# Template — action roguelite starter (Hades-like, original)
Status: implemented. Evidence: game-builder template tests green under `gb verify` at scaffold time.
- **Tests:** 5 unit tests (enemy brain, boons, boss readability, two balance contracts) plus the recipes' own
  tests; scenarios A1–A8 plus the recipes' scenarios and smoke, stable over `--repeat 3`.
- **Detection proven:**
  - hits cancelling a telegraph → the unit test goes red;
  - a dash without i-frames → A1 red;
  - death losing the embers → A5 red;
  - a boss move with a 0.25 s telegraph → the readability test red.
- **Screenshots looked at:** hub, boon choice, doors, enemy telegraph, boss lunge lane.
- **Found while building (by the bot):**
  - the boss lunge had no ground telegraph, and its lane was drawn narrower than it hurts;
  - the lunge tracked the player until the hit, so no late sidestep could work;
  - brutes hit for 30% of health.

  All were fixed, and they are now contracts.

Ladder rung: first playable (one complete loop: hub → 5 rooms → boss → hub, with meta progress)

## Goal
A tested starting point for an original action roguelite in the style of the genre (see
`gb doc genre-action-roguelite`):
- a hero with a melee combo and an invulnerable dash;
- runs of rooms whose waves come from an encounter director;
- a boon choice after rooms, and doors that show their reward;
- two enemy types with readable telegraphs;
- a phased boss;
- death that banks the run's embers for permanent upgrades at a shrine.

The art is placeholder (capsules, boxes).

## Design (built on recipes 05, 13, 43, 47–52 — added by scaffold with their tests)
- **Run** (`scenes/run/run.tscn`, `scripts/run/run.gd`, main scene) owns the loop: HUB → ROOM → REWARD → DOORS →
  … → OVER → HUB.
  - `RunMap`/`RunState`/`MetaProgress` (50): 5 rooms; no elites or shop yet; a rest before the boss.
  - `BoonCatalog` + `BoonPool` (48).
  - Meta progress is saved with `SaveSystem` (13) to `user://meta.json`. Test runs use their own file, and a save
    that can't be read is never overwritten.
  - `start_depth` starts a run at a later room, for playtesting one room and for the boss scenario.
  - Observable: `state`, `run`, `meta`, `owned`, `offer`, `room`, `hub`.
- **Player** (`scenes/player/player.tscn`, `scripts/player/player.gd`): moves on the ground plane (screen up = −Z).
  - `ComboMelee3D` (47) on `attack`, with damage × `attack_power`.
  - `Dash` (43) on `dash`: invulnerable, and it cancels recovery only, never a committed windup/active.
  - `Health` (05) with hurt i-frames.
  - Stats come from a `StatSheet` (48): speed, max_health, attack_power, burn_power.
  - Burning Blade applies a `StatusDef` burn (52) on hit.
- **Enemies** (`scenes/enemies/rusher|brute.tscn`, `scripts/enemies/enemy.gd` + `enemy_brain.gd`, data in
  `data/*.tres`):
  - chase → windup (red + "!", two cues) → strike (hits if in range and in front) → recover;
  - a hit staggers them only while chasing or recovering, never mid-telegraph;
  - Health with 0 i-frames, so combos land;
  - statuses tick into the same Health.
- **Room** (`scenes/room/room.tscn`, `scripts/room/room.gd`):
  - `EncounterDirector` (49) waves by depth (rusher from depth 0, brute from depth 1);
  - every spawn is announced by a glowing floor mark 0.5 s ahead;
  - `cleared` → the Run gives the reward → `show_doors()` → walking into a door chooses it.
- **Boss** (`scenes/boss/boss.tscn`, `scripts/boss/boss.gd`): `BossBrain` (51) with thresholds 66% / 33%, 1.2 s
  invulnerable transitions and `adds_per_phase` rushers. Moves:
  - **slam** is a disc of `slam_radius`;
  - **lunge** is a lane exactly `2 × contact_radius` wide and as long as the charge. It tracks the player until
    `lunge_lock` of the telegraph, then freezes;
  - **nova**, from phase 1, is a disc of `nova_radius`.
- **Hub** (`scenes/hub/hub.tscn`): a training dummy (47), the shrine (`action` → upgrades), and the run door.
- **UI** (`scripts/ui/rogue_ui.gd`, built in code): the HP bar, run status, boss bar, boon cards and shrine list, all
  driven by the game's own actions, and banners.
- **Input** (template actions): `attack` on J, the left mouse button and joypad X; `dash` on K, Shift and joypad A;
  plus the defaults (`move_*`, `action` = E/Enter).
- Forward+, Jolt, 1280×720.

## Tuning table
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| move_speed | 6 | m/s | data/player_tuning.tres | 4.5–8 |
| max_health | 60 | hp | player_tuning | 40–100 |
| attack_power | 1.0 | × | player_tuning | — |
| combo (windup/active/recovery, dmg) | 0.08/0.06/0.22 10 · 0.08/0.06/0.22 12 · 0.14/0.08/0.40 25 | s, hp | ComboMelee3D.default_combo (recipe 47) | ±30% |
| input buffer | 0.15 | s | ComboMelee3D.buffer_time | 0.1–0.2 |
| dash speed / duration / cooldown | 15 / 0.17 / 0.45 | m/s, s | player_tuning | 12–20 / 0.12–0.25 / 0.3–0.8 |
| dash i-frames after | 0.06 | s | player_tuning | 0–0.1 |
| hurt i-frames | 0.6 | s | player_tuning | 0.3–1.0 |
| rusher hp / dmg / telegraph | 30 / 6 / 0.45 | hp, hp, s | data/rusher.tres | — |
| brute hp / dmg / telegraph | 90 / 12 / 0.8 | hp, hp, s | data/brute.tres | — |
| wave budget | 3 + 1.5 × depth; +1 wave every 2 depths, max 3 | threat | room.gd | — |
| attack tokens | 2 | melee enemies winding up or striking at once | room.gd `@export attack_tokens` | 1–3 |
| boss hp / thresholds / transition | 420 / 66%, 33% / 1.2 | hp, s | boss.gd | 300–700 |
| boss moves (telegraph/strike/recovery, dmg) | slam 0.7/0.15/1.0 14 · lunge 0.6/0.35/0.9 12 · nova 1.0/0.2/1.2 18 | s, hp | RogueBoss.moves() | telegraph ≥ 0.4 |
| lunge_lock | 0.75 | × telegraph | boss.gd | 0.6–0.9 |
| adds_per_phase | 1 | rushers | boss.gd | 0–3 |
| rewards | currency 15 · heal 30% · rest 40% · sharpen +0.1 | — | run.gd consts | — |
| embers per kill | 1 | — | run.gd | — |
| upgrades | vitality +10 hp (cost 10 × lv, max 5) · might +0.1 (15 × lv, max 5) | — | run.gd `meta.upgrades` | — |

## Contracts (tests)
- **Readability:**
  - every boss move passes `BossBrain.validate()` (telegraph ≥ 0.4 s, recovery ≥ 0.5 s);
  - every telegraph shows where it hurts, at its true size;
  - enemy telegraphs are never cancelled by hits;
  - at most `attack_tokens` melee enemies wind up at once (AttackTokens). Added in 0.22.0 after the proof game: without
    it, overlapping tells made a crowded room cost a careful bot most of its health;
  - no input is taken blind (0.23.0, from the proof game):
    - a door arms `arm_time` (0.3 s) after it appears, so a rest room's instant doors can't catch the hero who just
      came through the same socket;
    - the boon choice ignores a pick for `pick_delay` (0.35 s), so a mashed attack doesn't choose unseen.
- **Balance at base stats:**
  - a rusher takes about one combo (0.3–1.2 s of perfect play);
  - a brute takes 1–3.5 s;
  - the boss takes 8–40 s;
  - no basic enemy hit is over 20% of base health, and no boss hit over 30%.
- **Completable:** A8 wins the whole base run with a simple bot that plays like a careful player:
  - it walks and attacks;
  - it starts no swing when a strike lands within 0.35 s (a swing can't be dash-cancelled);
  - it dashes away from all strikers in the last 0.15 s. A change that makes A8 fail made the base game too hard or soft-locked a room.

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| A1 | Walking covers move_speed × time; a dash covers ~speed × duration and a hit mid-dash does nothing | `a1_move_and_dash.gd` |
| A2 | The hub dummy takes the three swings in order, once each, scaled by attack power | `a2_combo_on_dummy.gd` |
| A3 | The run door starts a run; the first room is cleared; three boons are offered and the chosen one is owned; doors appear; walking into one enters room 2 | `a3_room_boon_doors.gd` |
| A4 | An enemy in range telegraphs before hitting; standing still gets you hit; dashing away during the telegraph avoids it | `a4_telegraph_and_dash.gd` |
| A5 | Dying banks the run's embers (one per kill, counted by the room's kill signal) and saves them to disk; back to the hub | `a5_death_banks.gd` |
| A6 | The shrine opens with `action`, Vitality costs 10 and raises max health at once and in the next run; `attack` closes it | `a6_shrine_upgrade.gd` |
| A7 | The boss telegraphs, changes phase at 66% and 33%, and a telegraph-reading bot beats it; victory returns to the hub | `a7_boss.gd` |
| A8 | The whole base run is winnable: hub → 5 rooms (first boon, first door) → boss → victory → embers banked | `a8_full_run.gd` |

## Next steps when a game starts from this
Replace placeholders with art (`gb doc starter-packs`: KayKit characters have Idle/Running/Jump clips → recipe 44).
Then extend in this order:
- more boons (conditional, build-shaping effects, per the genre doc);
- elites and a shop (RunMap already supports them);
- a second boss or area;
- a feel pass (`game-feel`, hit-stop done frame-based);
- a mastery-modifier system.

Keep A8 green, and rerun the balance contracts after every tuning change.
