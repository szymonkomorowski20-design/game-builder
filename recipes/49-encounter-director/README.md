# 49 — Encounter director (threat budget, waves, room cleared)

**Problem:** hand-placing every room's enemies doesn't scale to a roguelite's hundreds of rooms. Pure random spawns
fail in the other direction:
- rooms that are trivially easy or unfair;
- the same enemy five times;
- a ranged enemy in the very first room;
- the next wave landing on the player while the last one is still alive;
- the door opening twice.

**Solution:**
- **`EncounterDirector`** plans a room from a **threat budget**: `base_budget + budget_per_depth × depth` per wave,
  and `1 + depth / depth_per_extra_wave` waves (up to `max_waves`).
- Each `EnemyKind` has a `cost` and a `min_depth`, so types unlock as the run goes deeper.
- A wave first takes one of each affordable type (`variety`, shuffled), then fills the remaining budget at random
  until nothing fits. That gives mixed waves, and the budget is used up exactly when a 1-cost enemy exists.
- `plan(depth, seed)` is deterministic.
- At runtime:
  - `start()` spawns wave 0 through `wave_started`;
  - the host calls `enemy_died()` for each death;
  - the next wave comes `wave_delay` s after the previous one is **completely** gone;
  - `cleared` fires once, after the last wave. Open the doors and give the reward (recipes 48 and 50).

**Tuning:**
- costs per enemy type;
- `base_budget` and `budget_per_depth` (the difficulty curve; see the balance skill and recipe 36);
- `depth_per_extra_wave` and `max_waves`;
- `variety`;
- `wave_delay` (0.5–1.5 s: long enough to breathe, short enough to keep momentum);
- `min_depth` per type (introduce one new type at a time).

Elites are separate kinds with a higher cost and modifiers (recipe 48).

**Host:** spawn `EnemyKind.scene` at spawn points, show a short spawn telegraph (a glow, then the enemy appears ~0.5 s
later, so nothing materialises on top of the player), connect each enemy's death to `enemy_died()`. The demo stands
in for combat: `action` removes the oldest enemy, so the flow is visible.

**Pitfalls:**
- Counting spawned rather than alive enemies.
- Starting the next wave on a timer while enemies remain.
- Emitting `cleared` more than once (double rewards).
- Global RNG, which makes rooms unreproducible.
- A budget that only grows. Plan rest rooms, shops and elites as separate room types (recipe 50) so difficulty rises
  in waves, not in a straight line.

**Test:** `tests/unit/test_r49_encounters.gd` (budget fit and fill over 10 depths, growth and cap, `min_depth`
unlocks, mixed waves, determinism, waves advancing only when cleared plus the delay, `cleared` once),
`tests/scenarios/r49_encounter.gd` (the bot clears a depth-4 room: two waves in order, the door only at the end).
Scene: `encounter_demo.tscn`.
