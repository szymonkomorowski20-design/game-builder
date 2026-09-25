# 08 — Weapon: cooldown, magazine, reload

**Problem:** fire rate, ammo and reload are where shooters feel good or bad; timing must be exact and testable.

**Solution:** `Weapon` node with `try_fire(direction) -> bool`, `reload()`, `advance(delta)` for time (called from
`_process`, callable directly in tests). Signals `fired(projectile)`, `reloaded`, `empty` drive sounds, UI and animation.

**Tuning:** `cooldown`, `magazine_size`, `reload_time`, `projectile_scene`.

**Pitfalls:** timers as `await get_tree().create_timer()` scattered in input code (untestable, cancel badly);
firing sounds on `fire pressed` instead of on `fired`; allowing reload with a full magazine.

**Test:** `tests/unit/test_r08_weapon.gd` + the range scene used by recipe 07's scenario.
