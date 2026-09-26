# Template — top-down 2D arena starter
Status: implemented — evidence: game-builder template tests (tests/unit/test_player_health.gd, tests/scenarios/t*.gd) green under `gb verify` at scaffold time; detection proven (invulnerability 0 → T5 red; player without wall collision → T2 red)
Ladder rung: toy + tiny first-playable loop (move, shoot, survive two waves)

## Goal
A tested starting point for top-down action (twin-stick-lite, dungeon rooms, arena survival): responsive
8-direction movement tuned by numbers, shooting, enemies that chase and hurt on contact, invulnerability after a
hit, waves, a heart pickup, win/lose and restart. Placeholder art (shapes) — replace through the asset register.

## Design
- Player (`scenes/player/player.tscn`, `scripts/player/player.gd`): acceleration/friction movement from
  `Input.get_vector` (diagonals normalized), facing = last move direction, `action` held → shoot at
  `shoot_cooldown`; health with invulnerability after a hit; `died` signal. Observable: `health`, `shots_fired`,
  `facing`, `is_dead()`, `is_invulnerable()`.
- Bullet (`scenes/combat/bullet.tscn`): straight flight, damages the first enemy, stops at walls, expires.
- Enemy (`scenes/enemies/enemy.tscn`): chases the player at `move_speed`, contact damage through a `Hurt` area
  (repeats when the player's invulnerability ends), dies at 0 health.
- Arena (`scenes/level/arena.tscn`, `scripts/level/arena.gd`): 640×360 room with walls and a pillar, 3 spawn
  points, waves `[2, 3]`, `wave_delay` between waves, a heart (heals 1, not used at full health), HUD (health, wave,
  enemies), win/lose message, `pause` (Esc) restarts after the end. Observable: `wave`, `enemies_alive`, `kills`,
  `won`, `lost`, `score`.
- Collision layers: 1 walls · 2 player · 3 enemies (bullets mask walls + enemies; enemy Hurt masks the player).

## Tuning table (data/topdown_tuning.tres → TopDownTuning; enemy.gd; arena.gd)
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| move_speed | 150 | px/s | TopDownTuning | 100–220 |
| acceleration | 1200 | px/s² | TopDownTuning | 600–3000 |
| friction | 1500 | px/s² | TopDownTuning | 600–3000 |
| shoot_cooldown | 0.25 | s | TopDownTuning | 0.1–0.5 |
| bullet_speed | 420 | px/s | TopDownTuning | 250–700 |
| bullet_damage | 1 | hp | TopDownTuning | 1–3 |
| bullet_lifetime | 1.2 | s | TopDownTuning | 0.5–2 |
| max_health | 5 | hp | TopDownTuning | 3–10 |
| invulnerability | 0.8 | s | TopDownTuning | 0.4–1.5 |
| enemy move_speed | 60 | px/s | enemy.gd `@export` | 40–120 (below player speed) |
| enemy max_health | 2 | hp | enemy.gd | 1–5 |
| contact_damage | 1 | hp | enemy.gd | 1–2 |
| waves | [2, 3] | enemies | arena.gd | — |
| wave_delay | 0.6 | s | arena.gd | 0.5–3 |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| T1 | Holding a direction reaches move_speed; diagonals are not faster; friction stops | `t1_movement.gd` |
| T2 | Walls and the pillar stop the player | `t2_walls_block.gd` |
| T3 | Holding action fires at the cooldown rate in the facing direction; two hits kill an enemy | `t3_shoot_kills.gd` |
| T4 | Enemies close the distance at move_speed | `t4_enemy_chases.gd` |
| T5 | Contact hurts once; invulnerability protects; staying in contact hurts again | `t5_contact_damage.gd` |
| T6 | A heart is not used at full health; when hurt it heals 1 and disappears | `t6_heart_heals.gd` |
| T7 | Clearing a wave starts the next after wave_delay; the last wave wins | `t7_waves_win.gd` |
| T8 | At 0 health the player is dead, stops, and the lose message shows | `t8_death.gd` |
| — | Damage/heal/death rules | `tests/unit/test_player_health.gd` |

## Next steps for your game
Discovery decides the game; the next spec changes this template. Useful recipes (`gb recipe add`): 02 camera
follow for bigger rooms, 24 enemy AI with sight, 26 navigation, 27/28/37 tile rooms + generator + validation,
32/33/03 hit feedback, 34/35 audio, 13 save.
