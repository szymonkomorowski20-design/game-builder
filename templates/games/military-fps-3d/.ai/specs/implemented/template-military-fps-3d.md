# Template — military FPS campaign mission (Call of Duty-like, original)
Status: implemented. Evidence: game-builder template tests green under `gb verify` at scaffold time.
- **Tests:** 6 unit contracts plus the recipes' own tests (46 GUT tests in a scaffolded game); scenarios M1–M10 plus
  the recipes' scenarios and smoke (14), stable over `--repeat 3`.
- **Recipes that land:** 41, 49, 53–57, and 01 (recipe 41's demo and its scenario walk with recipe 01's 2D mover).
- **Detection proven** (15 deliberate breaks, each run against its check):
  - zones starting whenever the player stands in them, out of turn → M10;
  - a zone arming at once after a respawn → M7;
  - every soldier peeking at once → M5;
  - spawns not checked for line of sight → the spawn contract;
  - crouching that doesn't lower the head → M5;
  - no accuracy ramp → M5;
  - no suppression → M5;
  - regeneration ignoring its delay → M6;
  - a shot carrying its own recoil kick → M3;
  - no reload on an empty magazine → M2;
  - death not resetting the fight → M7;
  - no head zone → M4;
  - standing up with the head inside the body capsule → M4;
  - soldiers at 0.9 accuracy → the lethality contract.

  M8 did **not** catch the 0.9-accuracy soldiers: the bot kills a peeking soldier before it lands many shots. M8
  guards completability (flow, soft-locks, spawns); the lethality contract guards the numbers.
- **Screenshots looked at:** the start yard with the HUD, a soldier peeking over a crate, aiming down sights, firing
  (tracer, hit marker, "Przygwożdżony!" subtitle), a damage arc.
- **Found while building (by the bot):**
  - the first shot carried its own kick, so a headshot aimed at 25 m went over the head;
  - the soldiers' first wave ran across open ground to far cover and died before firing a shot (21 enemy shots in a
    whole mission). The first wave now starts dug in;
  - reinforcements had to appear in plain view when the player pushed deep into the warehouse (more spawn points,
    and a wave waits for a fair point);
  - suppression only counted where a bullet landed, not where it passed;
  - after a soldier crouched and stood up, its body capsule covered its head (headshots counted as body hits);
  - a soldier's hit tracer ran into the camera.

  The checker's review found one more: zones started on any trigger overlap, so a player who ran past the courtyard
  started the warehouse fight; the courtyard could then never clear, or clear late and take the objective back. Zones
  now start only in turn, and a respawn inside a trigger no longer restarts the fight at once (the physics server
  still had the player at the old spot for a frame).

  All were fixed, and they are now tests.

Ladder rung: first playable (one complete mission: start → two arenas → objective → reinforcements → extraction).

## Goal
A tested starting point for an original military FPS campaign in the style of the genre (see
`gb doc genre-military-fps`):
- a player with a rifle and a pistol that handle like the genre's guns;
- soldiers that take cover, peek, get suppressed, flank campers and say what they do;
- regenerating health with direction indicators;
- one linear mission with an objective line that always says what to do, checkpoints, and extraction.

The art is placeholder (boxes, capsules; red visors and armbands for readability).

## Design (built on recipes 41, 49, 53–57 — added by scaffold with their tests)
- **Mission** (`scenes/mission/mission.tscn`, `scripts/mission/mission.gd`, main scene):
  - the flow GATE → COURTYARD → TO_WAREHOUSE → WAREHOUSE → RADIO → REINFORCEMENTS → EXTRACT → COMPLETE. It only
    moves forward: a zone starts only when `can_start` says it is its turn, and a zone's `cleared` moves the stage
    only from that zone's own stage;
  - the objective line for each stage (Polish), and enemies left;
  - the navigation mesh is baked at start from the level's static colliders (`LevelBlock`s under `Level`);
  - `AttackTokens` (49): at most `attack_tokens` soldiers peek and fire at once;
  - `CheckpointTracker` (41): each arena's checkpoint is set when its fight starts; the radio sets the last one;
  - death: `respawn_delay` of the death screen, then back at the checkpoint with full health and full magazines.
    The unfinished fight is reset (its soldiers vanish, its trigger re-arms; the reinforcements restart after
    `reinforcements_delay`);
  - tracers for every shot; suppression of any soldier a bullet passed within `suppress_radius` of;
  - the mission-complete panel: time, accuracy, headshots, kills, deaths; `action` plays again.
  - Observable: `stage`, `deaths`, `elapsed`, `unfair_spawns`, `soldier_shots`, `soldier_hits`.
- **Arenas** (`scripts/mission/encounter_zone.gd`, three `EncounterZone`s: Courtyard, Warehouse, Extraction):
  - a trigger, `Cover/` markers behind low cover, `Spawns/` markers hidden from the way in, a `Checkpoint`;
  - the trigger is checked every frame, so a player already standing in it starts the fight when its turn comes;
    after a reset it arms 0.3 s later;
  - `waves`; the next wave `wave_delay` s after the previous is dead (49's rule); `cleared` once;
  - the first `dug_in_waves` waves start crouched at cover points that hide them from the player right now (they were
    there first); later waves run in from the spawns. The extraction wave always runs in (reinforcements).
- **Fair spawns** (`scripts/mission/spawn_picker.gd`, `SpawnPicker`): a point is fair when it is 12–45 m away, ahead
  along the arena's −Z, and hidden by geometry from the player's eye. A wave with too few fair points waits
  (0.5 s steps, up to 5 s) before it spawns anyway, and the mission counts that as an unfair spawn.
- **Player** (`scenes/player/player.tscn`, `scripts/player/mil_player.gd`, numbers in `data/player_tuning.tres`):
  - walk, sprint (no firing; cancels a reload), crouch (a toggle; the eye drops below low cover and the capsule
    shrinks), jump;
  - mouse look with `screen_relative`, and right-stick look with aim assist (56) for pads only;
  - two `GunModel`s (53) from `data/rifle.tres` and `data/pistol.tres`; aim down sights narrows the FOV and the
    spread; an emptied magazine reloads by itself;
  - the recoil is an offset on top of the aim (`kick_accumulated`): the view climbs while firing and settles after.
    A shot leaves along the view as it was when the trigger released it; its own kick moves the next shot;
  - `Hitscan` (54) from the camera; head / body zones from the soldier's shapes;
  - `RegenHealth` + `DamageIndicators` (55).
- **Soldiers** (`scenes/enemies/soldier.tscn`, `scripts/enemies/soldier.gd`, numbers in `data/soldier.tres`): the body
  for `ShooterBrain` and `CoverFinder` (57).
  - MOVE / FLANK: run the navigation path to the cover target (stuck for 2 s → hold where it is);
  - COVER / RELOAD: crouched (body 0–0.76 m, head 0.7–1.1 m: under low cover);
  - PEEK: standing, facing the player, bursts; each round hits with the brain's accuracy × `difficulty`, a miss draws
    a tracer past the player's head or shoulder;
  - every second in cover it checks that the cover still hides it from the player, and picks another if not;
  - barks: contact, reloading, flanking, suppressed, man down (subtitles in the HUD).
- **HUD** (`scripts/ui/mil_hud.gd`, built in code):
  - a crosshair whose gap is the gun's current spread, hidden while aiming or sprinting;
  - hit markers for body, head (yellow) and kill (red);
  - damage arcs and red screen edges below `danger_below`;
  - ammo and the gun, the objective and enemies left, bark subtitles, the radio's hold prompt and progress, the
    controls hint in the start yard, the death screen, the mission-complete panel.
- **Level** (built from `LevelBlock` boxes, generated once and then edited as a scene):
  - start yard (quiet, a practice crate);
  - gate;
  - courtyard (low crates near the gate, in the middle and far; a pillar and containers splitting sight lines);
  - warehouse (tall shelves splitting sight lines, low crates, the radio);
  - extraction yard (crates, two containers, the pad).

  Low cover is 1.1 m, walls 3–4 m.
- **Input** (template actions):

  | Action | Keyboard / mouse | Pad |
  |---|---|---|
  | `shoot` | F, left mouse | RT |
  | `aim` | right mouse | LT |
  | `reload` | R | X (also the default `action`: at the radio, `action` wins) |
  | `sprint` | Shift | L3 |
  | `crouch` | C, Ctrl | B |
  | `switch_weapon` | Q, mouse wheel | Y |
  | `look_*` | — | right stick |

  Plus the defaults (`move_*`, `jump`, `action` = E / Enter, `pause` = Esc).
- Forward+, Jolt, 1280×720. Layers: 1 world, 2 player, 3 soldiers.

## Tuning table
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| walk / sprint / crouch speed | 5.0 / 7.5 / 2.6 | m/s | data/player_tuning.tres | 4–6 / 6.5–8.5 / 2–3 |
| stand / crouch eye | 1.6 / 0.95 | m | player_tuning | crouch < low cover (1.1) |
| FOV / ADS scale | 90 / 0.72 | degrees, × | player_tuning | 80–100 / 0.6–0.8 |
| mouse sensitivity / ADS scale | 0.0022 / 0.7 | rad/px, × | player_tuning | — |
| max health / regen delay / rate | 100 / 4.0 / 40 | hp, s, hp/s | player_tuning | — / 3–5 / 25–50 |
| danger threshold | 0.4 | × max health | player_tuning | 0.3–0.5 |
| suppress radius | 2.0 | m | player_tuning | 1.5–3 |
| rifle | 700 rpm · 30 + 150 · 40 → 30 dmg (20–45 m) · head × 1.4 · hip 3° / ADS 0.3° · reloads 1.8 / 2.3 s | — | data/rifle.tres | TTK up close 0.1–0.3 s |
| pistol | semi 400 rpm · 12 + 60 · 36 → 22 dmg (12–30 m) · head × 1.4 · hip 1.8° / ADS 0.35° · reloads 1.3 / 1.6 s | — | data/pistol.tres | — |
| soldier health / speed | 100 / 5.2 | hp, m/s | data/soldier.tres | — |
| soldier gun | 450 rpm · bursts 3–5 · 0.35 s pause · 8 dmg · 20 rounds · reload 2.2 s | — | soldier.tres | pause > 0.3 |
| peek wait / peek time | 1.2 / 1.6 | s | soldier.tres | wait > 1 |
| accuracy min → max / aim time | 0.15 → 0.35 / 1.5 | chance, s | soldier.tres | min < 0.2 |
| flank after | 7 | s of the player not moving | soldier.tres | 5–10 |
| cover band near / far | 8 / 28 | m | soldier.tres | — |
| difficulty | 1.0 | × accuracy (0.7 easy, 1.3 hard) | mission.gd `difficulty` | — |
| attack tokens | 2 | soldiers peeking at once | mission.gd `attack_tokens` | 1–3 |
| waves | courtyard 3 + 2 · warehouse 2 + 2 · reinforcements 3 | soldiers | mission.tscn zones `waves` | — |
| dug-in waves | 1 (0 for the reinforcements) | first waves | zones `dug_in_waves` | — |
| wave delay | 1.5 | s | zones `wave_delay` | 0.5–3 |
| fair spawn distance | 12–45 | m | spawn_picker.gd | — |
| radio hold | 2.0 | s | Radio `hold_time` | 1.5–4 |
| respawn / reinforcements restart | 2.5 / 2.0 | s | mission.gd | — |

## Contracts (tests)
- **Time to kill** (`test_mil_contracts.gd`): the rifle kills a soldier in 3 body hits up close, 2 to the head, 4 at
  45 m; the pistol in 3–4 body hits up close, 2 to the head; the rifle's TTK up close is 0.1–0.3 s.
- **Lethality:** two soldiers peeking at once (the token limit), with the accuracy ramp, need more than 3.5 s to kill
  a full-health player standing in the open at normal difficulty, more than 2.5 s on hard; a third shooter would be
  deadlier (which is what the token limit prevents). The same on the real code (M5): a player standing in the open
  at the gate takes less than a full health bar in the first 3.5 s of fire.
- **Order:** the mission's stages only move forward; running past an arena starts nothing ahead (M10).
- **Readable fights:** a pause of more than 0.3 s between bursts; more than 1 s down between peeks; a peek's first
  shots use accuracy below 0.2; regeneration within 6 s; difficulty scales accuracy only, never timing; every bark
  has a Polish subtitle.
- **Fair spawns:** a point in plain view, closer than 12 m, or behind the player is never chosen while a fair one
  exists, and every unfair fill is counted.
- **Completable:** M8 finishes the mission with at most 1 death and no unfair spawn, with a bot that plays like a
  careful player:
  - a 0.25 s reaction;
  - an aim error that settles from 2.5° to 0.6° in 0.7 s;
  - centre mass beyond 12 m;
  - short bursts, pulling down 80% of the recoil;
  - cover when below half health.

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| M1 | Walking, sprinting (no shots), crouch-walking and aimed walking cover their speeds; crouching lowers the eye to crouch_eye and back | `m1_move_stance.gd` |
| M2 | The rifle fires its rpm; an empty magazine reloads by itself with the longer empty reload; a tactical reload; sprinting cancels a reload and loads nothing; the pistol fires once per press | `m2_gun_rate_reload.gd` |
| M3 | Aiming narrows the FOV and the spread and hides the crosshair; a burst climbs the view and it settles; the same burst kicks the same way; the crosshair opens with bloom; the first shot lands where the sights were at 46 m | `m3_ads_recoil.gd` |
| M4 | Head, body and kill hits deal their damage and show their marker, also after the soldier crouched and stood up | `m4_hit_zones.gd` |
| M5 | The first wave starts dug in, heads hidden; at most `attack_tokens` peek at once; the first shot of a peek uses accuracy_min; they fire; less than a health bar of hits in the first 3.5 s of fire at a player in the open; a bullet passing close suppresses a peeking soldier, with its bark | `m5_soldiers.gd` |
| M6 | A hit from the right shows an arc on the right; same-side hits refresh one arc; no regeneration before regen_delay, then a full refill; red edges at low health | `m6_regen_indicators.gd` |
| M7 | Death shows the death screen, then the checkpoint with full health; the unfinished fight is reset, and walking in starts it again | `m7_checkpoint.gd` |
| M8 | The whole mission is completable by a careful bot, with at most 1 death and no unfair spawn | `m8_full_mission.gd` |
| M9 | The radio works only after the warehouse; holding fills it, letting go resets it; done → checkpoint, and reinforcements running in out of sight | `m9_radio_hold.gd` |
| M10 | Running past the courtyard fight into the warehouse doorway starts nothing there and keeps the objective; once the courtyard is cleared, the warehouse fight starts with the player already in it; the objective only moved forward | `m10_rush_past.gd` |

## Next steps when a game starts from this
Replace the placeholders with art: `gb doc starter-packs` (a character pack with idle / run / aim / crouch clips →
recipe 44), a weapon view model, sounds (gunshots layered near / far, the dry click, reload steps, the voice barks
from the genre doc's list). Then extend, in this order:
- a second enemy type from the genre doc's archetypes (a flanker that rushes, a shielded one);
- grenades, one per squad (an `AttackTokens` with `limit` 1 per squad), announced by a bark;
- more missions: a quiet stretch, a set piece, a one-off mechanic per mission;
- difficulty selection (`difficulty` is the only knob that should change);
- settings (sensitivity, FOV, aim assist on / off);
- a feel pass (`game-feel`: sway, head bob, shake on firing, hit-stop on kills).

Keep M8 green, and rerun the contracts after every tuning change.
