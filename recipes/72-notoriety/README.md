# 72 — Notoriety and the chase (levels with named effects, witnesses who report, a search circle, escaping)

**Problem:** consequences that are all-or-nothing (genre doc §8–§9):
- a kill in plain view changes nothing, or ends the mission;
- a wanted state that never ends, or ends the moment the player turns a corner;
- guards who know about a crime nobody reported;
- no way to lower notoriety except waiting.

**Solution:** two small parts.
- **`Notoriety`:** a value 0–100, read as levels 0–3 at 25 / 55 / 85.
  - `witnessed(act, by_guard, now)` adds `ACTS[act]` (a kill 30, a fight 15, a trespass 10, a theft 8, a shove 3, a
    climb seen 2).
    - A guard's sighting counts at once.
    - A civilian's is a report due after `report_time` (6 s). `stop_witness(id)` in time, and nothing is reported
      (the witnesses of Watch Dogs).
  - `tick(now, delta)` applies due reports, and the optional `decay_per_s`.
  - `tear_poster()` takes off 25 and `bribe_herald()` halves the value (Assassin's Creed II's posters and heralds).
    There is no decay by default.
  - `effect()` gives the level's named effects:
    - `notice`: the multiplier for how fast guards notice, applied to recipe 68's rate;
    - `attack_on_sight` (level 3);
    - `roof_guards` (from level 2);
    - `hunter` (level 3).
- **`WantedSearch`:**
  - `SEEN` while a guard sees the player: call `seen(at, now, level)` every frame it does;
  - `LOST` after `lost_after` (0.5 s) unseen. A circle stays at the last seen place, its radius set by the level
    (15 / 20 / 30 / 40 m);
  - `ESCAPED` after `escape_time` (4 s) outside the circle, or `hide_time` (3 s) hidden in hay, on a bench or in a
    crowd. Being seen again restarts everything (GTA IV, Assassin's Creed II);
  - `is_chased()`, `reset()`.

**Host (the game):**
- Report acts with who saw them. A guard's senses (recipe 68) seeing a kill means `by_guard = true`; a civilian's
  line of sight means a report. Show the pending report over the witness, so the player can stop it.
- Multiply the guards' notice rate by `effect().notice`.
- Put archers on the roofs and send a hunter when the effects say so. A parkour game needs an answer to a player on
  the roofs (genre doc §5).
- Draw the circle on the minimap (recipe 45) while `LOST`.
- In a contract (recipe 73), escaping is a phase, not a failure.

**Tuning:**
- the act amounts and the three thresholds;
- `report_time` 6 s; poster −25; herald ×0.5; `decay_per_s` 0 (or 0.2 for a gentle game);
- the notice multipliers 1.0 / 1.3 / 1.7 / 2.5;
- the circle radii 15–40 m, `escape_time` 4 s, `hide_time` 3 s.

The series publishes no notoriety amounts and no decay rates (genre doc, "Not established").

**Pitfalls:**
- **A wanted timer that runs from the last sighting,** not from leaving the circle: players escape by standing still
  around a corner.
- **A circle that follows the player:** the search should stay where the player was last seen. Guards don't know the
  rest (recipe 69).
- **A report counted the moment a civilian sees a crime:** there is nothing to stop, and witnesses don't matter.
- **Notoriety only ever going up:** without posters or heralds the district locks the player out.

**Test:** `tests/unit/test_r72_notoriety.gd`:
- levels from acts, and the cap;
- a civilian's report after its delay, and a stopped witness;
- posters, heralds and optional decay;
- effects rising with the level;
- escaping by leaving the circle (and the timer restarting when the player goes back in);
- escaping by hiding, and being seen again while hidden.
