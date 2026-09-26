# 32 — Hit-stop (freeze frame)

**Problem:** hits feel weightless.

**Solution:** on a strong hit drop `Engine.time_scale` to ~0.05 for 40–100 ms of **real** time
(`create_timer(duration, true, false, true)` — the last `true` ignores time scale), then restore. A counter makes
overlapping stops extend instead of cutting each other short. Combine with camera shake (03), hit flash (33), a
particle burst and a sound (21): the "juice" stack. Scale duration with damage; skip it for weak/frequent hits.

**Pitfalls:** timers/tweens that follow time scale never finish while time is ~0 (use `ignore_time_scale`); leaving
time_scale at 0.05 when the scene changes (restore in `_exit_tree`); hit-stop in multiplayer (never touch global time
there — freeze only the involved characters); physics tick count drops with time_scale, so gameplay stays consistent.

**Test:** `tests/scenarios/r32_hit_stop.gd`.
