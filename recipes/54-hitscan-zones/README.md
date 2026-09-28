# 54 — Hitscan with hit zones (3D)

**Problem:**
- Headshots need to know *which part* of an enemy was hit. One collider per enemy can't tell a head from a chest, and
  a separate Area3D per zone doubles every physics query.
- Spread offsets (recipe 53) have to bend the shot around the camera's own axes, not the world's.

**Solution:** **`Hitscan`**:
- `shot_direction(camera.global_basis, shot.offset)` bends forward (−Z) by yaw and pitch in degrees, around the
  camera's own axes;
- `cast(world, from, dir, max_range, mask, exclude)` runs one ray and returns `{collider, position, normal, distance,
  zone}`, or `{}` for a miss;
- the **zone** is metadata `hit_zone` (`&"head"`, `&"body"`, `&"limb"`) on the CollisionShape3D the ray hit. The ray
  result's `shape` index maps to its owner node through `shape_find_owner` / `shape_owner_get_owner`. So an enemy is
  one CharacterBody3D with a sphere for the head and a capsule for the torso, each tagged;
- damage = `GunModel.damage_at(hit.distance, hit.zone)` (recipe 53).

**Host:**
- For each `Shot` from recipe 53:
  - `var dir := Hitscan.shot_direction(camera.global_basis, shot.offset)`;
  - `var hit := Hitscan.cast(get_world_3d(), camera.global_position, dir, stats.max_range, mask, [player.get_rid()])`.
- If it hit something that `has_method(&"take_hit")`, pass the damage.
- Spawn the impact effect at `hit.position` facing `hit.normal`.
- Draw a tracer from the muzzle (not the camera) to the hit point.

**Pitfalls:**
- casting from the muzzle instead of the camera (shots miss what the crosshair covers);
- the shooter's own body in the ray (exclude its RID);
- head shapes so small they only count at a standstill (0.2–0.25 m radius on a human-sized body is common);
- zones on child nodes with their own collision objects (then `collider` is the child, not the enemy);
- reading the zone from a node name instead of metadata (breaks when scenes are renamed).

**Test:** `tests/unit/test_r54_hitscan.gd`:
- shot directions, following the camera's axes;
- the head and body zones, and the distance;
- out of range;
- a wall in between, and excluding the shooter;
- headshot damage through recipe 53.
