# 06 — Hitbox / hurtbox

**Problem:** attacks, spikes and projectiles must damage the right things, once per contact, without every
script checking every body.

**Solution:** two small `Area2D` classes. `Hitbox` (layer 3, detects nothing, carries `damage`);
`Hurtbox` (no layer, masks layer 3, knows its `Health`). The victim's hurtbox reports `area_entered` →
`Health.take_damage`. One contact = one hit; i-frames in Health stop multi-hits.

**Layers (project convention):** 1 world, 2 player, 3 hitboxes, 4 enemies — name them in Project Settings →
Layer Names so the Inspector shows words.

**Pitfalls:** both areas monitoring each other (double hits); forgetting that `area_entered` fires once per entry
(continuous damage zones need a timer); disabling a hitbox by hiding it (use `monitorable = false` or
`set_deferred("monitorable", false)` inside physics callbacks).

**Test:** `tests/scenarios/r06_hitbox_hurtbox.gd`. Uses recipe 05 Health.
