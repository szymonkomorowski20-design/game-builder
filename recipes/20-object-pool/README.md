# 20 — Object pool

**Problem:** hundreds of bullets/sparks per second → instantiate + `queue_free` churn causes frame spikes.

**Solution:** `NodePool` with a `scene`, `prewarm(n)` at level load, `acquire()` (reuse a parked node or create up to
`max_size`) and `release(n)` (hide + `PROCESS_MODE_DISABLED`). Pooled nodes reset themselves in `on_acquired()` /
`on_released()`. The projectile recipe (07) would call `pool.release(self)` instead of `queue_free()`.

**Measure first:** `node tools/gb/gb.js perf` before and after. GDScript instantiation of a small scene is cheap; pool
only when the profiler shows it. GPUParticles2D is already pooled internally — don't pool particles yourself.

**Pitfalls:** state leaking between uses (reset velocity, health, timers in `on_acquired`); signals connected on every
acquire (connect once in `_ready`); double release; collision still active on parked nodes if the shape isn't disabled
(PROCESS_MODE_DISABLED stops scripts, not physics — disable the `CollisionShape2D` or move it far away).

**Test:** `tests/unit/test_r20_pool.gd`.
