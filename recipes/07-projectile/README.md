# 07 — Projectile

**Problem:** bullets, arrows and fireballs: fly, hit once, disappear; never live forever.

**Solution:** `Projectile extends Hitbox` (recipe 06): moves itself in `_physics_process`, dies after `lifetime`, and
disappears when the victim's Hurtbox calls `on_hit_landed`. No second collision setup — the victim detects, as for melee.

**Tuning:** `speed` (px/s), `lifetime` (s), `damage` (from Hitbox).

**Pitfalls:** freeing or toggling physics properties inside a physics callback (use `set_deferred` / `queue_free`);
very fast projectiles skipping thin targets (increase the shape along the direction, or use a `RayCast2D`/`ShapeCast2D`
sweep); spawning under the shooter's own hurtbox; forgetting a lifetime (leaks nodes). For many bullets see pooling (recipe 31).

**Test:** `tests/scenarios/r07_projectile_hits.gd` (hit → damage → removed; miss → removed after lifetime).
