# 03 — Screen shake (trauma)

**Problem:** hits and explosions need punch, but random per-frame offsets look like jitter and stacked shakes explode.

**Solution:** `ShakeCamera2D.add_trauma(x)`; trauma ∈ [0, 1] decays linearly; the visible strength is trauma²;
offset/rotation come from `FastNoiseLite` sampled over time (smooth), scaled by `max_offset`/`max_roll`.
Typical amounts: small hit 0.2, big hit 0.5, explosion 0.8.

**Tuning:** `decay`, `max_offset`, `max_roll`. Offer a screen-shake slider in settings (accessibility) and scale `max_offset` by it.

**Pitfalls:** shaking `position` (fights follow and limits — use `offset`); `randf()` per frame (jitter); no clamp on trauma.

**Test:** `tests/unit/test_r03_camera_shake.gd` (drives `advance(delta)` directly — deterministic).
Idea source: GDC talk "Math for Game Programmers: Juicing Your Cameras With Math" (Squirrel Eiserloh).
