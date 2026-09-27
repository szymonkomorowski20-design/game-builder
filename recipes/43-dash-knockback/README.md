# 43 — Dash and knockback (with i-frames)

**Problem:** a dash that can be spammed, that leaves the player hittable mid-dash, or that fights with knockback; a
knockback that stacks several hits into a launch across the level, or pushes toward the enemy.

**Solution:** two pure objects the body asks every physics frame. `Dash`: `try_start(dir)` (refused during the
cooldown or without a direction), `velocity()` during the burst, `is_invulnerable()` through the burst +
`iframes_after`. `Knockback`: `hit(source, body_position, strength)` pushes away from the source, decaying linearly
over `duration`; a new hit replaces the push. `DashMover` shows the priority: dash, then knockback, then walking.
Hits go through `take_hit()`, which respects the i-frames.

**Tuning (put these in your Tuning table):** dash `speed`, `duration`, `cooldown`, `iframes_after`; knockback
`strength` (per hit source) and `duration`. Rule of thumb: dash distance = speed × duration ≈ 2–4 player widths;
cooldown ≥ 3 × duration so it reads as a burst, not a movement mode.

**Pitfalls:** cooldown counted from the dash's end instead of its start (feels sluggish); checking i-frames in the
enemy instead of the target (every enemy must remember); steering during the burst (the dash wobbles); knockback
added to the velocity every frame without decay; dash + knockback both writing `velocity` (pick one per frame).
Pair the hit with recipe 32 (hit-stop) and 33 (hit flash) for feel.

**Test:** `tests/unit/test_r43_dash_knockback.gd`, `tests/scenarios/r43_dash_knockback.gd`. Scene: `dash_demo.tscn`.
