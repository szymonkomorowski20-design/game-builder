# 05 — Health & damage component

**Problem:** every hurtable thing (player, enemy, crate) needs the same rules: damage, brief invulnerability after a hit, death once, healing capped.

**Solution:** a `Health` node added as a child; others call `take_damage(n)` / `heal(n)`; listeners use the signals
`damaged`, `healed`, `died` (HUD, flash shader, death animation, score). Composition over inheritance — the owner's
script stays small.

**Tuning:** `max_health`, `invulnerability_time` (0 for enemies hit by multi-hit attacks, 0.5–1.0 s for the player).

**Pitfalls:** `died` emitted every hit at zero (guard with `is_dead()`); overkill making health negative;
healing dead actors; putting i-frame timing in `_physics_process` of the owner instead of the component.

**Test:** `tests/unit/test_r05_health.gd` (drives `advance(delta)` for time).
