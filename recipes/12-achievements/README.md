# 12 — Achievements (stat-driven)

**Problem:** achievements scattered as `if` checks everywhere, unlocking twice or not at all after loading a save.

**Solution:** the game only reports stats (`add_stat(&"coins")`); achievements are data (`define(id, stat, target)`)
and unlock once when a stat crosses the target. Save `stats` + `unlocked` ids. Platform APIs (Steam) are an adapter that
listens to `unlocked` — never called from gameplay code.

**Pitfalls:** unlocking from UI code; re-firing unlocks after load (keep the id list); floats from JSON (cast).

**Test:** `tests/unit/test_r12_achievements.gd`.
